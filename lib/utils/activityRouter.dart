import 'package:flutter/material.dart';
import '../activity/breathing_screen.dart';
import '../activity/mindfulWalk_screen.dart';
import '../activity/gratitudeJournaling_screen.dart';
import '../activity/creativeExpression_screen.dart';
import '../activity/genericActivity_screen.dart'; 

class ActivityRouter {
  static Widget screenFor(
    String activityName, {
    String? duration,
    String? steps,
  }) {
    final name = activityName.toLowerCase();

    if (name.contains('breath')) {
      return const BreathingScreen();
    } else if (name.contains('walk') || name.contains('ground')) {
      return const MindfulWalkScreen();
    } else if (name.contains('gratitude') || name.contains('journal')) {
      return const GratitudeJournalingScreen();
    } else if (name.contains('creative') || name.contains('express')) {
      return const CreativeExpressionScreen();
    }

    // 通用页面 fallback
    return GenericActivityScreen(
      name: activityName,
      duration: duration ?? '10 min',
      steps: steps ?? 'Take a moment to focus on this activity mindfully.',
    );
  }

  static void navigate(
    BuildContext context,
    String activityName, {
    String? duration,
    String? steps,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screenFor(activityName, duration: duration, steps: steps),
      ),
    );
  }
}