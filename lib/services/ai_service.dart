import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/diary_entry.dart';

class AiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // ── FIX 4: timeout duration constant ─────────────────────────────────────
  static const Duration _timeout = Duration(seconds: 20);

  static Future<Map<String, dynamic>> analyzeDiaryEntry({
    required String entryText,
    required int mood,
    required List<DiaryEntry> recentEntries,
  }) async {
    final moodLabels = ['Awful', 'Bad', 'Okay', 'Good', 'Great'];
    final currentMoodLabel = moodLabels[mood.clamp(0, 4)];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // ── PRIVACY: sort chronologically (oldest → newest) before building context
    // ── PRIVACY: history entries use structured AI-analysed data only (no raw text)
    //            only the CURRENT entry's raw text is sent to the AI.
    //            this minimises exposure of sensitive personal diary content
    //            to the third-party Gemini API.
    final sortedHistory = [...recentEntries]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final historyContext = sortedHistory.take(7).map((e) {
      final dayName = days[e.createdAt.weekday - 1];
      final trigger = (e.triggerKeyword != null && e.triggerKeyword!.isNotEmpty)
          ? ' | Trigger: ${e.triggerKeyword}'
          : '';
      final intensity = e.emotionIntensity != null
          ? ' | Intensity: ${e.emotionIntensity!.toStringAsFixed(1)}/10'
          : '';
      // ── only structured fields, no raw entryText ──────────────────────────
      return '- [$dayName ${e.createdAt.day}/${e.createdAt.month}] Mood: ${e.moodLabel} (${e.mood}/4)$intensity$trigger';
    }).join('\n');

    final prompt = '''
You are a compassionate emotional wellness assistant.

Current Entry (full text provided for analysis):
- Date: ${_weekdayName(DateTime.now().weekday)}
- Mood: $currentMoodLabel
- Text: "$entryText"

Recent History (oldest to newest, structured data only):
${historyContext.isEmpty ? 'No previous entries.' : historyContext}

ANALYSIS INSTRUCTIONS:
1. emotionIntensity: Rate 1-10 based on emotional INTENSITY only, not positivity/negativity.
   - 1-3: Calm, mild, subdued (e.g. "okay day", "feeling fine", "a bit tired")
   - 4-6: Moderate emotion (e.g. "stressed about work", "pretty happy today")
   - 7-9: Strong emotion (e.g. "really anxious", "so excited", "very upset")
   - 10: Overwhelming emotion (e.g. "can't stop crying", "best day of my life")
   A happy entry can score 9 if the joy is overwhelming. A sad entry can score 2 if it's mild.
   Base it on the WORDS used, not the mood emoji selected.
2. triggerKeyword: Extract the most specific root cause phrase. One phrase only.
3. validation: 2 supportive sentences. Acknowledge their exact feeling first. Never say "I understand".
4. patternInsight: ONLY fill this if there are AT LEAST 3 previous entries AND you see a clear
   recurring pattern with timing if possible (e.g. "Your mood tends to drop mid-week").
   Leave empty string if fewer than 3 entries or no clear pattern.
5. activitySuggestion: MUST be exactly one of these options based on mood level:
   - Awful/Bad → "Box Breathing" or "Guided Meditation" or "Sleep Hygiene"
   - Okay → "Gratitude Journaling" or "Mindful Walk" or "Body Stretching"
   - Good/Great → "Creative Expression" or "Mindful Walk"
   Only return the activity name, nothing else.
6. activityDuration: Return the duration string for the chosen activity.
   - Box Breathing → "5 min"
   - Guided Meditation → "10 min"
   - Sleep Hygiene → "8 min"
   - Gratitude Journaling → "10 min"
   - Mindful Walk → "15 min"
   - Body Stretching → "7 min"
   - Creative Expression → "15 min"
7. activitySteps: Exactly 3 steps, each under 15 words, specific to the suggested activity.
8. reflectiveSummary: Under 50 words, hopeful and forward-looking.

Respond ONLY with valid JSON.
Do NOT use markdown code blocks.
Do NOT include \`\`\`json or \`\`\` in your response.
All newline characters inside strings MUST be escaped as \\n.

{
  "emotionIntensity": 0.0,
  "triggerKeyword": "",
  "validation": "",
  "patternInsight": "",
  "activitySuggestion": "",
  "activityDuration": "",
  "activitySteps": "1. Step one\\n2. Step two\\n3. Step three",
  "reflectiveSummary": ""
}
''';

    try {
      if (_apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in .env');
      }

      // ── FIX 4: added .timeout() ───────────────────────────────────────────
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": prompt}
                  ]
                }
              ]
            }),
          )
          .timeout(_timeout);

      // ── FIX 3: replaced print() with debugPrint() ─────────────────────────
      debugPrint("analyzeDiaryEntry STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        final cleaned = _cleanJson(text);
        final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

        return {
          'emotionIntensity':
              (parsed['emotionIntensity'] as num?)?.toDouble() ?? 0.0,
          'triggerKeyword': (parsed['triggerKeyword'] ?? '').toString(),
          'validation': (parsed['validation'] ?? '').toString(),
          'patternInsight': (parsed['patternInsight'] ?? '').toString(),
          'activitySuggestion':
              (parsed['activitySuggestion'] ?? '').toString(),
          'activityDuration': (parsed['activityDuration'] ?? '').toString(),
          'activitySteps': (parsed['activitySteps'] ?? '').toString(),
          'reflectiveSummary': (parsed['reflectiveSummary'] ?? '').toString(),
        };
      } else {
        debugPrint("analyzeDiaryEntry ERROR: ${response.statusCode}");
        if (response.statusCode == 429) {
          return {
            ...fallbackResponse(mood),
            'isFallback': true,
            'error': 'quota_exceeded',
          };
        }
        return fallbackResponse(mood);
      }
    } catch (e) {
      debugPrint("analyzeDiaryEntry EXCEPTION: $e");
      return fallbackResponse(mood);
    }
  }

  // ── Weekly Summary ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> generateWeeklySummary(
      List<DiaryEntry> entries) async {
    if (entries.isEmpty) {
      return _fallbackWeeklySummary(entries);
    }

    // ── FIX 5: compute streaks in Dart instead of letting AI guess ────────
    final sortedEntries = [...entries]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final streaks = _computeStreaks(sortedEntries);
    final dartPositiveStreak = streaks['positiveStreak']!;
    final dartNegativeStreak = streaks['negativeStreak']!;
    final dartAvgMoodScore = entries.isEmpty
        ? 2.0
        : entries.map((e) => e.mood).reduce((a, b) => a + b) /
            entries.length;

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // ── PRIVACY: weekly summary also uses structured data only (no raw text)
    //            raw diary text has already been analysed per-entry.
    //            we send only the AI-extracted structured signals for pattern detection.
    final entriesText = sortedEntries.map((e) {
      final dayName = days[e.createdAt.weekday - 1];
      final trigger = (e.triggerKeyword != null && e.triggerKeyword!.isNotEmpty)
          ? ' | Trigger: ${e.triggerKeyword}'
          : '';
      final intensity = e.emotionIntensity != null
          ? ' | Intensity: ${e.emotionIntensity!.toStringAsFixed(1)}/10'
          : '';
      // ── only structured fields, no raw entryText ──────────────────────────
      return '[$dayName ${e.createdAt.day}/${e.createdAt.month}] Mood: ${e.moodLabel} (${e.mood}/4)$intensity$trigger';
    }).join('\n');

    final prompt = '''
You are a compassionate emotional wellness coach analyzing a user's diary from the past 7 days.
Your job is to think like a detective — find hidden patterns across time, not just summarize feelings.

Here are the diary entries in chronological order (oldest to newest):
$entriesText

Pre-computed stats (use these exact numbers — do NOT recalculate):
- avgMoodScore: ${dartAvgMoodScore.toStringAsFixed(2)}
- positiveStreak: $dartPositiveStreak
- negativeStreak: $dartNegativeStreak

ANALYSIS INSTRUCTIONS:
1. Look for TIME-BASED patterns (e.g., mood drops on specific days of the week)
2. Identify RECURRING TRIGGERS by comparing what was written across multiple entries
3. Detect EMOTIONAL TRAJECTORY — is the user improving, declining, or stuck in a cycle?
4. If negativeStreak >= 3, set riskFlag to true and write a warm, non-clinical riskMessage
5. weeklySummary should read like a caring friend who remembers everything you shared this week
6. recurringTrigger should be specific (e.g., "work deadlines on weekdays" not just "stress")

Respond ONLY in this JSON format, no extra text:
{
  "dominantEmotion": "",
  "avgMoodScore": ${dartAvgMoodScore.toStringAsFixed(2)},
  "recurringTrigger": "",
  "sourceOfNegativity": "",
  "emotionalTrajectory": "improving | declining | fluctuating | stable",
  "weeklySummary": "",
  "hiddenInsight": "",
  "positiveStreak": $dartPositiveStreak,
  "negativeStreak": $dartNegativeStreak,
  "riskFlag": ${dartNegativeStreak >= 3},
  "riskMessage": ""
}

Notes:
- hiddenInsight: one surprising connection the user probably hasn't noticed themselves
- riskMessage: if riskFlag is true, suggest ONE gentle action (e.g., "Maybe reach out to someone you trust today")
- Keep weeklySummary under 80 words, personal and warm
- avgMoodScore, positiveStreak, negativeStreak are pre-computed — copy them as-is into your response
''';

    try {
      if (_apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in .env');
      }

      // ── FIX 4: added .timeout() ───────────────────────────────────────────
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": prompt}
                  ]
                }
              ]
            }),
          )
          .timeout(_timeout);

      debugPrint("generateWeeklySummary STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        final cleaned = _cleanJson(text);
        final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

        // ── FIX 5: always use Dart-computed values for numeric stats ─────
        return {
          'dominantEmotion': (parsed['dominantEmotion'] ?? '').toString(),
          'avgMoodScore': dartAvgMoodScore,
          'recurringTrigger': (parsed['recurringTrigger'] ?? '').toString(),
          'sourceOfNegativity':
              (parsed['sourceOfNegativity'] ?? '').toString(),
          'emotionalTrajectory':
              (parsed['emotionalTrajectory'] ?? '').toString(),
          'weeklySummary': (parsed['weeklySummary'] ?? '').toString(),
          'hiddenInsight': (parsed['hiddenInsight'] ?? '').toString(),
          'positiveStreak': dartPositiveStreak,
          'negativeStreak': dartNegativeStreak,
          'riskFlag': dartNegativeStreak >= 3,
          'riskMessage': (parsed['riskMessage'] ?? '').toString(),
        };
      } else {
        debugPrint("generateWeeklySummary ERROR: ${response.statusCode}");
        return _fallbackWeeklySummary(entries);
      }
    } catch (e) {
      debugPrint("generateWeeklySummary EXCEPTION: $e");
      return _fallbackWeeklySummary(entries);
    }
  }

  static Map<String, int> _computeStreaks(List<DiaryEntry> sortedEntries) {
    if (sortedEntries.isEmpty) {
      return {'positiveStreak': 0, 'negativeStreak': 0};
    }

 
    final Map<String, DiaryEntry> latestPerDay = {};
    for (final e in sortedEntries) {
      final dayKey = '${e.createdAt.year}-${e.createdAt.month}-${e.createdAt.day}';
      final existing = latestPerDay[dayKey];
      if (existing == null || e.createdAt.isAfter(existing.createdAt)) {
        latestPerDay[dayKey] = e;
      }
    }

    final dailyEntries = latestPerDay.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 计算 streak
    int positiveStreak = 0;
    for (final e in dailyEntries) {
      if (e.mood >= 3) positiveStreak++;
      else break;
    }

    int negativeStreak = 0;
    for (final e in dailyEntries) {
      if (e.mood <= 1) negativeStreak++;
      else break;
    }

    return {
      'positiveStreak': positiveStreak,
      'negativeStreak': negativeStreak,
    };
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _weekdayName(int weekday) {
    const names = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return names[(weekday - 1).clamp(0, 6)];
  }

  static String _cleanJson(String rawText) {
    String text = rawText.trim();
    text = text.replaceAll('```json', '').replaceAll('```', '').trim();

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      text = text.substring(start, end + 1);
    }

    final buffer = StringBuffer();
    bool inString = false;
    bool escapeNext = false;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (escapeNext) {
        buffer.write(char);
        escapeNext = false;
        continue;
      }

      if (char == r'\') {
        buffer.write(char);
        escapeNext = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        buffer.write(char);
        continue;
      }

      if (inString && (char == '\n' || char == '\r')) {
        buffer.write(r'\n');
        continue;
      }

      buffer.write(char);
    }

    return buffer.toString();
  }

  // ── Fallback responses ─────────────────────────────────────────────────────

  static Map<String, dynamic> fallbackResponse(int mood) {
    final responses = [
      // mood 0 — Awful
      {
        'emotionIntensity': 8.0,
        'triggerKeyword': 'overwhelming stress',
        'validation':
            "It's completely okay to feel this way. You're carrying a lot right now and that takes real strength.",
        'patternInsight': '',
        'activitySuggestion': 'Box Breathing',
        'activityDuration': '5 min',
        'activitySteps':
            '1. Sit comfortably and close your eyes.\n2. Inhale for 4 counts, hold for 4, exhale for 4.\n3. Repeat 4 times and notice the calm.',
        'reflectiveSummary':
            'You showed up today even when things felt heavy. That takes courage — tomorrow holds new possibilities.',
      },
      // mood 1 — Bad
      {
        'emotionIntensity': 6.0,
        'triggerKeyword': 'daily pressure',
        'validation':
            "Feeling down is a natural part of life. It's okay not to be okay — this moment will pass.",
        'patternInsight': '',
        'activitySuggestion': 'Guided Meditation',
        'activityDuration': '10 min',
        'activitySteps':
            '1. Find a quiet spot and sit comfortably.\n2. Breathe slowly and let your thoughts drift by.\n3. Stay with the stillness for a few minutes.',
        'reflectiveSummary':
            'Every step forward counts, even the small ones. Keep going — you are doing better than you think.',
      },
      // mood 2 — Okay
      {
        'emotionIntensity': 3.0,
        'triggerKeyword': 'routine',
        'validation':
            "Ordinary days have their own quiet value. Rest and steadiness are productive too.",
        'patternInsight': '',
        'activitySuggestion': 'Gratitude Journaling',
        'activityDuration': '10 min',
        'activitySteps':
            '1. Write three things you are grateful for today.\n2. Keep each one simple and specific.\n3. Reflect briefly on why each one matters.',
        'reflectiveSummary':
            'Stable days build a strong foundation for better ones ahead. You are right where you need to be.',
      },
      // mood 3 — Good
      {
        'emotionIntensity': 5.0,
        'triggerKeyword': 'positive moments',
        'validation':
            "It's wonderful that you're feeling good today. Savour this feeling — you deserve it.",
        'patternInsight': '',
        'activitySuggestion': 'Mindful Walk',
        'activityDuration': '15 min',
        'activitySteps':
            '1. Step outside at a relaxed pace.\n2. Notice the sounds, air, and surroundings around you.\n3. Let yourself enjoy the moment fully.',
        'reflectiveSummary':
            'Your positive energy today is something to celebrate. Carry this feeling with you into tomorrow.',
      },
      // mood 4 — Great
      {
        'emotionIntensity': 7.5,
        'triggerKeyword': 'joy and connection',
        'validation':
            "You're radiating great energy today! Keep nurturing the things and people that bring you this joy.",
        'patternInsight': '',
        'activitySuggestion': 'Creative Expression',
        'activityDuration': '15 min',
        'activitySteps':
            '1. Pick any creative activity that excites you.\n2. Create freely without judging the result.\n3. Enjoy the process and let the energy flow.',
        'reflectiveSummary':
            'Great days like this remind us what we are working toward. Let this joy fuel the days ahead.',
      },
    ];

    return responses[mood.clamp(0, 4)];
  }

  static Map<String, dynamic> _fallbackWeeklySummary(
      List<DiaryEntry> entries) {
    final streaks = _computeStreaks(
      [...entries]..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
    );
    final avg = entries.isEmpty
        ? 2.0
        : entries.map((e) => e.mood).reduce((a, b) => a + b) /
            entries.length;

    return {
      'dominantEmotion':
          avg >= 3 ? 'Content' : avg >= 2 ? 'Neutral' : 'Stressed',
      'avgMoodScore': avg,
      'recurringTrigger': 'daily routine',
      'sourceOfNegativity': '',
      'emotionalTrajectory': 'stable',
      'weeklySummary':
          'You have been consistently showing up and reflecting on your emotions this week. That takes real dedication.',
      'hiddenInsight': '',
      'positiveStreak': streaks['positiveStreak']!,
      'negativeStreak': streaks['negativeStreak']!,
      'riskFlag': streaks['negativeStreak']! >= 3,
      'riskMessage': '',
    };
  }
}