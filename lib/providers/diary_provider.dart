import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';
import '../services/ai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryProvider extends ChangeNotifier {
  List<DiaryEntry> _entries = [];
  bool _isAnalyzing = false;
  Map<String, dynamic>? _weeklySummary;
  bool _isLoadingWeekly = false;

<<<<<<< HEAD
  // 🔥 新加：Firebase Firestore 实例
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
=======
  // ── Search & Filter state ──────────────────────────────────────────────────
  String _searchQuery = '';
  int? _filterMood; // null = all, 0-4 = specific mood
>>>>>>> 22fe38b3e6301b4a7496c3660e0f2a605c74d6a5

  List<DiaryEntry> get entries => _entries;
  bool get isAnalyzing => _isAnalyzing;
  Map<String, dynamic>? get weeklySummary => _weeklySummary;
  bool get isLoadingWeekly => _isLoadingWeekly;
  String get searchQuery => _searchQuery;
  int? get filterMood => _filterMood;

  // ── Filtered entries ───────────────────────────────────────────────────────
  List<DiaryEntry> get filteredEntries {
    var result = [..._entries];
    if (_filterMood != null) {
      result = result.where((e) => e.mood == _filterMood).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) =>
          e.entryText.toLowerCase().contains(q) ||
          e.moodLabel.toLowerCase().contains(q) ||
          (e.triggerKeyword?.toLowerCase().contains(q) ?? false) ||
          (e.aiReflection?.toLowerCase().contains(q) ?? false)).toList();
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

  // ── Computed getters ───────────────────────────────────────────────────────
  List<DiaryEntry> get last7Days {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _entries
        .where((e) => e.createdAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  DiaryEntry? get todayEntry {
    final today = DateTime.now();
    try {
      return _entries.firstWhere((e) =>
          e.createdAt.year == today.year &&
          e.createdAt.month == today.month &&
          e.createdAt.day == today.day);
    } catch (_) {
      return null;
    }
  }

  bool get hasRiskFlag {
    if (_entries.length < 3) return false;
    final sorted = [..._entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(3).every((e) => e.mood <= 1);
  }

  DiaryProvider() {
    _loadEntries();
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('diary_entries') ?? [];
    _entries = raw
        .map((s) => DiaryEntry.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'diary_entries',
      _entries.map((e) => jsonEncode(e.toMap())).toList(),
    );
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────
  Future<DiaryEntry> addEntry({
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
    await _saveEntries(); // 保留原有本地存储
    
    // 🔥 新加：同步到云端 Firebase
    try {
      await _firestore.collection('diary_entries').doc(entry.id).set(entry.toMap());
    } catch (e) {
      debugPrint("Firebase Add Error: $e");
    }

    notifyListeners();
    _analyzeEntry(entry);
    return entry;
  }

<<<<<<< HEAD
  Future<void> _analyzeEntry(DiaryEntry entry) async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      final result = await AiService.analyzeDiaryEntry(
        entryText: entry.entryText,
        mood: entry.mood,
        recentEntries: last7Days.where((e) => e.id != entry.id).toList(),
      );

      final updated = entry.copyWith(
        aiReflection: result['reflectiveSummary'] as String?,
        triggerKeyword: result['triggerKeyword'] as String?,
        emotionIntensity: (result['emotionIntensity'] as num?)?.toDouble(),
      );

      final idx = _entries.indexWhere((e) => e.id == entry.id);
      if (idx != -1) {
        _entries[idx] = updated;
        await _saveEntries(); // 保留原有本地更新

        // 🔥 新加：更新云端 Firebase 里的 AI 结果
        try {
          await _firestore.collection('diary_entries').doc(entry.id).update(updated.toMap());
        } catch (e) {
          debugPrint("Firebase Update Error: $e");
        }
      }
    } catch (_) {
      // Silently fail — entry is still saved without AI data
    }

    _isAnalyzing = false;
    notifyListeners();
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
=======
  /// Edit an existing entry (text + mood). Clears old AI data, re-analyzes.
  Future<DiaryEntry> editEntry({
    required String id,
    required String entryText,
    required int mood,
  }) async {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx == -1) throw Exception('Entry not found');

    final updated = DiaryEntry(
      id: id,
      entryText: entryText,
      mood: mood,
      createdAt: _entries[idx].createdAt, // keep original timestamp
    );
    _entries[idx] = updated;
    await _saveEntries();
>>>>>>> 22fe38b3e6301b4a7496c3660e0f2a605c74d6a5
    notifyListeners();
    _analyzeEntry(updated); // re-run AI analysis
    return updated;
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _saveEntries(); // 保留原有本地删除

    // 🔥 新加：从云端 Firebase 删除
    try {
      await _firestore.collection('diary_entries').doc(id).delete();
    } catch (e) {
      debugPrint("Firebase Delete Error: $e");
    }

    notifyListeners();
  }

  // ── AI Analysis ────────────────────────────────────────────────────────────
  Future<void> _analyzeEntry(DiaryEntry entry) async {
    _isAnalyzing = true;
    notifyListeners();
    try {
      final result = await AiService.analyzeDiaryEntry(
        entryText: entry.entryText,
        mood: entry.mood,
        recentEntries: last7Days.where((e) => e.id != entry.id).toList(),
      );
      final updated = entry.copyWith(
        aiReflection: result['reflectiveSummary'] as String?,
        triggerKeyword: result['triggerKeyword'] as String?,
        emotionIntensity: (result['emotionIntensity'] as num?)?.toDouble(),
      );
      final idx = _entries.indexWhere((e) => e.id == entry.id);
      if (idx != -1) {
        _entries[idx] = updated;
        await _saveEntries();
      }
    } catch (_) {}
    _isAnalyzing = false;
    notifyListeners();
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
      final entry = _entries.firstWhere((e) =>
          e.createdAt.year == date.year &&
          e.createdAt.month == date.month &&
          e.createdAt.day == date.day);
      return entry.mood;
    } catch (_) {
      return null;
    }
  }
}