import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/diary_entry.dart';
import '../services/ai_service.dart';

class DiaryProvider extends ChangeNotifier {
  List<DiaryEntry> _entries = [];
  bool _isAnalyzing = false;
  Map<String, dynamic>? _weeklySummary;
  bool _isLoadingWeekly = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _authSubscription;

  String _searchQuery = '';
  int? _filterMood;

  List<DiaryEntry> get entries => _entries;
  bool get isAnalyzing => _isAnalyzing;
  Map<String, dynamic>? get weeklySummary => _weeklySummary;
  bool get isLoadingWeekly => _isLoadingWeekly;
  String get searchQuery => _searchQuery;
  int? get filterMood => _filterMood;

  DiaryProvider() {
    _authSubscription = _auth.authStateChanges().listen((_) async {
      await loadEntries();
    });

    loadEntries();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  String get _guestStorageKey => 'diary_entries_guest';

  String _userStorageKey(String uid) => 'diary_entries_user_$uid';

  CollectionReference<Map<String, dynamic>> _userEntriesRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('diary_entries');
  }

  List<DiaryEntry> get filteredEntries {
    var result = [..._entries];

    if (_filterMood != null) {
      result = result.where((e) => e.mood == _filterMood).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) {
        return e.entryText.toLowerCase().contains(q) ||
            e.moodLabel.toLowerCase().contains(q) ||
            (e.triggerKeyword?.toLowerCase().contains(q) ?? false) ||
            (e.aiReflection?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return result;
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterMood(int? mood) {
    _filterMood = mood;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterMood = null;
    notifyListeners();
  }

  List<DiaryEntry> get last7Days {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _entries.where((e) => e.createdAt.isAfter(cutoff)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  DiaryEntry? get todayEntry {
    final today = DateTime.now();
    try {
      return _entries.firstWhere(
        (e) =>
            e.createdAt.year == today.year &&
            e.createdAt.month == today.month &&
            e.createdAt.day == today.day,
      );
    } catch (_) {
      return null;
    }
  }

  bool get shouldShowWeeklySummary {
    if (hasRiskFlag) return true;
    if (_entries.isNotEmpty && _entries.length % 7 == 0) return true;
    return false;
  }

  bool get hasRiskFlag {
    if (_entries.length < 3) return false;

    final sorted = [..._entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sorted.take(3).every((e) => e.mood <= 1) ||
        sorted.take(5).where((e) => e.mood <= 1).length >= 4;
  }

  Future<void> loadEntries() async {
    final user = _auth.currentUser;

    if (user == null) {
      await _loadLocalEntries(_guestStorageKey);
    } else {
      await _loadUserEntries(user.uid);
    }

    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> _loadLocalEntries(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(key) ?? [];

    _entries = raw
        .map((s) => DiaryEntry.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveLocalEntries(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      key,
      _entries.map((e) => jsonEncode(e.toMap())).toList(),
    );
  }

  Future<void> _loadUserEntries(String uid) async {
    try {
      final snapshot =
          await _userEntriesRef(uid).orderBy('createdAt', descending: true).get();

      _entries = snapshot.docs
          .map((doc) => DiaryEntry.fromMap(_normalizeFirestoreMap(doc.data())))
          .toList();
    } catch (e) {
      debugPrint('Firestore load error: $e');
      await _loadLocalEntries(_userStorageKey(uid));
    }
  }

  Future<void> _cacheUserEntriesLocally(String uid) async {
    await _saveLocalEntries(_userStorageKey(uid));
  }

  Map<String, dynamic> _normalizeFirestoreMap(Map<String, dynamic> data) {
    final map = Map<String, dynamic>.from(data);

    if (map['createdAt'] is Timestamp) {
      map['createdAt'] =
          (map['createdAt'] as Timestamp).toDate().toIso8601String();
    }

    return map;
  }

  Map<String, dynamic> _entryToFirestoreMap(DiaryEntry entry) {
    final map = Map<String, dynamic>.from(entry.toMap());

    if (map['createdAt'] is String) {
      map['createdAt'] =
          Timestamp.fromDate(DateTime.parse(map['createdAt'] as String));
    } else if (map['createdAt'] is DateTime) {
      map['createdAt'] = Timestamp.fromDate(map['createdAt'] as DateTime);
    } else if (map['createdAt'] == null) {
      map['createdAt'] = Timestamp.fromDate(entry.createdAt);
    }

    return map;
  }

  Future<void> migrateGuestEntriesToCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final guestRaw = prefs.getStringList(_guestStorageKey) ?? [];
    if (guestRaw.isEmpty) return;

    final guestEntries = guestRaw
        .map((s) => DiaryEntry.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList();

    try {
      final batch = _firestore.batch();

      for (final entry in guestEntries) {
        final ref = _userEntriesRef(user.uid).doc(entry.id);
        batch.set(ref, _entryToFirestoreMap(entry), SetOptions(merge: true));
      }

      await batch.commit();
      await prefs.remove(_guestStorageKey);
      await loadEntries();
    } catch (e) {
      debugPrint('Guest migration error: $e');
    }
  }

  Future<Map<String, dynamic>> addEntry({
    required String entryText,
    required int mood,
  }) async {
    final entry = DiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      entryText: entryText,
      mood: mood,
      createdAt: DateTime.now(),
    );

    _entries.insert(0, entry);

    final user = _auth.currentUser;

    if (user == null) {
      await _saveLocalEntries(_guestStorageKey);
    } else {
      await _saveEntryToFirestore(user.uid, entry);
      await _cacheUserEntriesLocally(user.uid);
    }

    notifyListeners();

    final aiResult = await _analyzeAndUpdate(entry);
    return {'entry': entry, 'aiResult': aiResult};
  }

  Future<Map<String, dynamic>> editEntry({
    required String id,
    required String entryText,
    required int mood,
  }) async {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx == -1) throw Exception('Entry not found');

    final existing = _entries[idx];

    final updated = DiaryEntry(
      id: id,
      entryText: entryText,
      mood: mood,
      createdAt: existing.createdAt,
      aiReflection: existing.aiReflection,
      triggerKeyword: existing.triggerKeyword,
      emotionIntensity: existing.emotionIntensity,
      activitySuggestion: existing.activitySuggestion,
      activityDuration: existing.activityDuration,
      activitySteps: existing.activitySteps,
      validation: existing.validation,
      patternInsight: existing.patternInsight,
    );

    _entries[idx] = updated;

    final user = _auth.currentUser;

    if (user == null) {
      await _saveLocalEntries(_guestStorageKey);
    } else {
      await _updateEntryInFirestore(user.uid, updated);
      await _cacheUserEntriesLocally(user.uid);
    }

    notifyListeners();

    final aiResult = await _analyzeAndUpdate(updated);
    return {'entry': updated, 'aiResult': aiResult};
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);

    final user = _auth.currentUser;

    if (user == null) {
      await _saveLocalEntries(_guestStorageKey);
    } else {
      await _deleteEntryFromFirestore(user.uid, id);
      await _cacheUserEntriesLocally(user.uid);
    }

    notifyListeners();
  }

  Future<void> clearAllEntries() async {
    final user = _auth.currentUser;

    if (user == null) {
      _entries.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestStorageKey);
      notifyListeners();
      return;
    }

    try {
      final snapshot = await _userEntriesRef(user.uid).get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      _entries.clear();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userStorageKey(user.uid));

      notifyListeners();
    } catch (e) {
      debugPrint('Clear user entries error: $e');
    }
  }

  Future<void> _saveEntryToFirestore(String uid, DiaryEntry entry) async {
    try {
      await _userEntriesRef(uid).doc(entry.id).set(_entryToFirestoreMap(entry));
    } catch (e) {
      debugPrint("Firebase Add Error: $e");
    }
  }

  Future<void> _updateEntryInFirestore(String uid, DiaryEntry entry) async {
    try {
      await _userEntriesRef(uid).doc(entry.id).set(
            _entryToFirestoreMap(entry),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint("Firebase Update Error: $e");
    }
  }

  Future<void> _deleteEntryFromFirestore(String uid, String id) async {
    try {
      await _userEntriesRef(uid).doc(id).delete();
    } catch (e) {
      debugPrint("Firebase Delete Error: $e");
    }
  }

  Future<Map<String, dynamic>> _analyzeAndUpdate(DiaryEntry entry) async {
    _isAnalyzing = true;
    notifyListeners();

    Map<String, dynamic> result = AiService.fallbackResponse(entry.mood);

    try {
      result = await AiService.analyzeDiaryEntry(
        entryText: entry.entryText,
        mood: entry.mood,
        recentEntries: last7Days.where((e) => e.id != entry.id).toList(),
      );

      final updated = entry.copyWith(
        aiReflection: result['reflectiveSummary'] as String?,
        triggerKeyword: result['triggerKeyword'] as String?,
        emotionIntensity: (result['emotionIntensity'] as num?)?.toDouble(),
        activitySuggestion: result['activitySuggestion'] as String?,
        activityDuration: result['activityDuration'] as String?,
        activitySteps: result['activitySteps'] as String?,
        validation: result['validation'] as String?,
        patternInsight: result['patternInsight'] as String?,
      );

      final idx = _entries.indexWhere((e) => e.id == entry.id);
      if (idx != -1) {
        _entries[idx] = updated;

        final user = _auth.currentUser;

        if (user == null) {
          await _saveLocalEntries(_guestStorageKey);
        } else {
          await _updateEntryInFirestore(user.uid, updated);
          await _cacheUserEntriesLocally(user.uid);
        }
      }
    } catch (_) {}

    _isAnalyzing = false;
    notifyListeners();
    return result;
  }

  Future<void> loadWeeklySummary() async {
    _isLoadingWeekly = true;
    notifyListeners();

    try {
      _weeklySummary = await AiService.generateWeeklySummary(last7Days);
    } catch (_) {
      _weeklySummary = null;
    }

    _isLoadingWeekly = false;
    notifyListeners();
  }

  int? getMoodForDate(DateTime date) {
    try {
      final entry = _entries.firstWhere(
        (e) =>
            e.createdAt.year == date.year &&
            e.createdAt.month == date.month &&
            e.createdAt.day == date.day,
      );
      return entry.mood;
    } catch (_) {
      return null;
    }
  }
}