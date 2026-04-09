import 'package:flutter/material.dart';

class DiaryEntry {
  final String id;
  final String entryText;
  final int mood; // 0=Awful, 1=Bad, 2=Okay, 3=Good, 4=Great
  final DateTime createdAt;
  final String? aiReflection;
  final String? triggerKeyword;
  final double? emotionIntensity;

  DiaryEntry({
    required this.id,
    required this.entryText,
    required this.mood,
    required this.createdAt,
    this.aiReflection,
    this.triggerKeyword,
    this.emotionIntensity,
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
    String? aiReflection,
    String? triggerKeyword,
    double? emotionIntensity,
  }) {
    return DiaryEntry(
      id: id,
      entryText: entryText,
      mood: mood,
      createdAt: createdAt,
      aiReflection: aiReflection ?? this.aiReflection,
      triggerKeyword: triggerKeyword ?? this.triggerKeyword,
      emotionIntensity: emotionIntensity ?? this.emotionIntensity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entryText': entryText,
      'mood': mood,
      'createdAt': createdAt.toIso8601String(),
      'aiReflection': aiReflection,
      'triggerKeyword': triggerKeyword,
      'emotionIntensity': emotionIntensity,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'],
      entryText: map['entryText'],
      mood: map['mood'],
      createdAt: DateTime.parse(map['createdAt']),
      aiReflection: map['aiReflection'],
      triggerKeyword: map['triggerKeyword'],
      emotionIntensity: map['emotionIntensity'] != null
          ? (map['emotionIntensity'] as num).toDouble()
          : null,
    );
  }
}
