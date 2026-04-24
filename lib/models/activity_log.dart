import 'package:flutter/material.dart';

class ActivityLog {
  final String id;
  final String activityName;
  final DateTime completedAt;
  final String? userContent; // for Gratitude & Creative Expression

  ActivityLog({
    required this.id,
    required this.activityName,
    required this.completedAt,
    this.userContent,
  });

  // ── Icon & Color helpers ──────────────────────────────────────────────────

  IconData get icon {
    final name = activityName.toLowerCase();
    if (name.contains('breath')) return Icons.air;
    if (name.contains('meditat')) return Icons.self_improvement;
    if (name.contains('sleep')) return Icons.bedtime_outlined;
    if (name.contains('walk') || name.contains('ground')) return Icons.directions_walk;
    if (name.contains('stretch') || name.contains('body')) return Icons.accessibility_new;
    if (name.contains('gratitude') || name.contains('journal')) return Icons.edit_note;
    if (name.contains('creative') || name.contains('express')) return Icons.brush_outlined;
    return Icons.spa;
  }

  Color get color {
    final name = activityName.toLowerCase();
    if (name.contains('breath')) return const Color(0xFF1D9E75);
    if (name.contains('meditat')) return const Color(0xFF534AB7);
    if (name.contains('sleep')) return const Color(0xFF378ADD);
    if (name.contains('walk') || name.contains('ground')) return const Color(0xFF5A8A2F);
    if (name.contains('stretch') || name.contains('body')) return const Color(0xFFEF9F27);
    if (name.contains('gratitude') || name.contains('journal')) return const Color(0xFFBA7517);
    if (name.contains('creative') || name.contains('express')) return const Color(0xFFE24B4A);
    return const Color(0xFF1D9E75);
  }

  Color get bgColor {
    final name = activityName.toLowerCase();
    if (name.contains('breath')) return const Color(0xFFE1F5EE);
    if (name.contains('meditat')) return const Color(0xFFEEEDFE);
    if (name.contains('sleep')) return const Color(0xFFDDEEFA);
    if (name.contains('walk') || name.contains('ground')) return const Color(0xFFEAF3DE);
    if (name.contains('stretch') || name.contains('body')) return const Color(0xFFFAEEDA);
    if (name.contains('gratitude') || name.contains('journal')) return const Color(0xFFFAEEDA);
    if (name.contains('creative') || name.contains('express')) return const Color(0xFFFAECE7);
    return const Color(0xFFE1F5EE);
  }

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'activityName': activityName,
        'completedAt': completedAt.toIso8601String(),
        'userContent': userContent,
      };

  factory ActivityLog.fromMap(Map<String, dynamic> map) => ActivityLog(
        id: map['id'] as String,
        activityName: map['activityName'] as String,
        completedAt: DateTime.parse(map['completedAt'] as String),
        userContent: map['userContent'] as String?,
      );
}