import 'package:flutter/material.dart';

class DiaryEntry {
  final String id;
  final String entryText;
  final int mood; // 0=Awful, 1=Bad, 2=Okay, 3=Good, 4=Great
  final DateTime createdAt;

  final String? aiReflection;
  final String? triggerKeyword;
  final double? emotionIntensity;
  final String? activitySuggestion;

  final String? validation;
  final String? patternInsight;
  final String? activityDuration;
  final String? activitySteps;

  DiaryEntry({
    required this.id,
    required this.entryText,
    required this.mood,
    required this.createdAt,
    this.aiReflection,
    this.triggerKeyword,
    this.emotionIntensity,
    this.activitySuggestion,
    this.validation,
    this.patternInsight,
    this.activityDuration,
    this.activitySteps,
  });

  String get moodLabel {
    const labels = ['Awful', 'Bad', 'Okay', 'Good', 'Great'];
    return labels[mood.clamp(0, 4)];
  }

  String get moodEmoji {
    const emojis = ['😣', '😞', '😐', '😊', '😄'];
    return emojis[mood.clamp(0, 4)];
  }

  Color get moodColor {
    const colors = [
      Color(0xFFE24B4A),
      Color(0xFFEF9F27),
      Color(0xFF888780),
      Color(0xFF1D9E75),
      Color(0xFF378ADD),
    ];
    return colors[mood.clamp(0, 4)];
  }

  DiaryEntry copyWith({
    String? id,
    String? entryText,
    int? mood,
    DateTime? createdAt,
    String? aiReflection,
    String? triggerKeyword,
    double? emotionIntensity,
    String? activitySuggestion,
    String? validation,
    String? patternInsight,
    String? activityDuration,
    String? activitySteps,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      entryText: entryText ?? this.entryText,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      aiReflection: aiReflection ?? this.aiReflection,
      triggerKeyword: triggerKeyword ?? this.triggerKeyword,
      emotionIntensity: emotionIntensity ?? this.emotionIntensity,
      activitySuggestion: activitySuggestion ?? this.activitySuggestion,
      validation: validation ?? this.validation,
      patternInsight: patternInsight ?? this.patternInsight,
      activityDuration: activityDuration ?? this.activityDuration,
      activitySteps: activitySteps ?? this.activitySteps,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entryText': entryText,
      'mood': mood,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'aiReflection': aiReflection,
      'triggerKeyword': triggerKeyword,
      'emotionIntensity': emotionIntensity,
      'activitySuggestion': activitySuggestion,
      'validation': validation,
      'patternInsight': patternInsight,
      'activityDuration': activityDuration,
      'activitySteps': activitySteps,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: (map['id'] ?? '').toString(),
      entryText: (map['entryText'] ?? '').toString(),
      mood: (map['mood'] ?? 2) as int,
      createdAt: () {
        final raw = map['createdAt'].toString();
        final dt = DateTime.parse(raw);
        // 如果字符串没有时区标记（不含Z或+），当本地时间处理
        if (!raw.contains('Z') && !raw.contains('+')) {
          return dt; // 已经是本地时间，不用转
        }
        return dt.toLocal();
      }(),
      aiReflection: map['aiReflection']?.toString(),
      triggerKeyword: map['triggerKeyword']?.toString(),
      emotionIntensity: map['emotionIntensity'] != null
          ? (map['emotionIntensity'] as num).toDouble()
          : null,
      activitySuggestion: map['activitySuggestion']?.toString(),
      validation: map['validation']?.toString(),
      patternInsight: map['patternInsight']?.toString(),
      activityDuration: map['activityDuration']?.toString(),
      activitySteps: map['activitySteps']?.toString(),
    );
  }
}