import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_log.dart';

class ActivityProvider extends ChangeNotifier {
  List<ActivityLog> _logs = [];

  List<ActivityLog> get logs => _logs;

  // ── Recent logs ───────────────────────────────────────────────────────────

  List<ActivityLog> get last7Days {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _logs
        .where((l) => l.completedAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  List<ActivityLog> get recentLogs {
    return [..._logs]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  int get totalCompleted => _logs.length;

  int get completedThisWeek => last7Days.length;

  // Most done activity this week
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

  ActivityProvider() {
    _loadLogs();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('activity_logs') ?? [];
    _logs = raw
        .map((s) => ActivityLog.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    notifyListeners();
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'activity_logs',
      _logs.map((l) => jsonEncode(l.toMap())).toList(),
    );
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> logActivity({
    required String activityName,
    String? userContent,
  }) async {
    final log = ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityName: activityName,
      completedAt: DateTime.now(),
      userContent: userContent,
    );
    _logs.insert(0, log);
    await _saveLogs();
    notifyListeners();
  }

  Future<void> deleteLog(String id) async {
    _logs.removeWhere((l) => l.id == id);
    await _saveLogs();
    notifyListeners();
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

  Future<void> forceRefresh() async {
    await _loadLogs();
  }

}