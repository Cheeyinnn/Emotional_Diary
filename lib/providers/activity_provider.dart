import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/activity_log.dart';

class ActivityProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ActivityLog> _logs = [];
  bool _isLoading = false;

  List<ActivityLog> get logs => _logs;
  bool get isLoading => _isLoading;

  // ── Firestore reference ───────────────────────────────────────────────────

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (_uid == null) return null;
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('activity_logs');
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadLogs() async {
    if (_collection == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _collection!
          .orderBy('completedAt', descending: true)
          .get();

      _logs = snapshot.docs
          .map((doc) => ActivityLog.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('ActivityProvider.loadLogs error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Filtered logs ─────────────────────────────────────────────────────────

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  List<ActivityLog> get recentLogs {
    return [..._logs]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  List<ActivityLog> get last7Days {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _logs
        .where((l) => l.completedAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  List<ActivityLog> get logsToday {
    final today = _startOfDay(DateTime.now());
    return _logs
        .where((l) => !_startOfDay(l.completedAt).isBefore(today))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  List<ActivityLog> get logsThisWeek {
    final cutoff =
        _startOfDay(DateTime.now()).subtract(const Duration(days: 6));
    return _logs
        .where((l) => !_startOfDay(l.completedAt).isBefore(cutoff))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  List<ActivityLog> get logsThisMonth {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _logs
        .where((l) => !_startOfDay(l.completedAt).isBefore(startOfMonth))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  List<ActivityLog> get logsThisYear {
    final startOfYear = DateTime(DateTime.now().year, 1, 1);
    return _logs
        .where((l) => !_startOfDay(l.completedAt).isBefore(startOfYear))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  int get totalCompleted => _logs.length;

  int get completedThisWeek => last7Days.length;

  String? get topActivityThisWeek {
    if (last7Days.isEmpty) return null;
    final counts = <String, int>{};
    for (final log in last7Days) {
      counts[log.activityName] = (counts[log.activityName] ?? 0) + 1;
    }
    return counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  Map<String, int> get top5Activities {
    final counts = <String, int>{};
    for (final log in last7Days) {
      counts[log.activityName] = (counts[log.activityName] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> logActivity({
    required String activityName,
    String? userContent,
  }) async {
    if (_collection == null) return;

    final now = DateTime.now();
    final data = {
      'activityName': activityName,
      'completedAt': Timestamp.fromDate(now),
      'userContent': userContent,
    };

    try {
      // Write to Firestore, use generated doc ID
      final docRef = await _collection!.add(data);

      // Optimistic local update — no need to reload entire list
      final log = ActivityLog(
        id: docRef.id,
        activityName: activityName,
        completedAt: now,
        userContent: userContent,
      );
      _logs.insert(0, log);
      notifyListeners();
    } catch (e) {
      debugPrint('ActivityProvider.logActivity error: $e');
    }
  }

  Future<void> deleteLog(String id) async {
    if (_collection == null) return;

    try {
      await _collection!.doc(id).delete();
      _logs.removeWhere((l) => l.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('ActivityProvider.deleteLog error: $e');
    }
  }

  Future<void> forceRefresh() async {
    await loadLogs();
  }
}