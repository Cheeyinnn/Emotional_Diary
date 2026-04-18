import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/diary_entry.dart';

class AiService {

  static const String _apiKey = 'AIzaSyAABt4UE3-tQss2XpZKINmkpNWbZPdemYs';

  // Gemini endpoint
  static const String _apiUrl =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// ✅ Analyze single diary entry
  static Future<Map<String, dynamic>> analyzeDiaryEntry({
    required String entryText,
    required int mood,
    required List<DiaryEntry> recentEntries,
  }) async {
    final moodLabels = ['Awful', 'Bad', 'Okay', 'Good', 'Great'];
    final currentMoodLabel = moodLabels[mood.clamp(0, 4)];

    final historyContext = recentEntries.take(7).map((e) {
      return '- ${e.createdAt.day}/${e.createdAt.month}: Mood=${e.moodLabel}, Entry="${e.entryText.substring(0, e.entryText.length.clamp(0, 80))}..."';
    }).join('\n');

    final prompt = '''
You are a compassionate emotional wellness assistant. Think step by step before responding.

Current Entry:
- Date: ${DateTime.now().weekday == 1 ? "Monday" : DateTime.now().weekday == 2 ? "Tuesday" : DateTime.now().weekday == 3 ? "Wednesday" : DateTime.now().weekday == 4 ? "Thursday" : DateTime.now().weekday == 5 ? "Friday" : DateTime.now().weekday == 6 ? "Saturday" : "Sunday"}
- Mood: $currentMoodLabel
- Text: "$entryText"

Recent History (chronological):
${historyContext.isEmpty ? 'No previous entries.' : historyContext}

ANALYSIS INSTRUCTIONS:
1. emotionIntensity: Rate 1-10. Consider BOTH the words used AND the mood level. "Fine" at Bad mood = higher intensity than face value.
2. triggerKeyword: Extract the SPECIFIC root cause (e.g. "exam pressure" not just "stress"). One phrase only.
3. validation: 2 sentences. Acknowledge their exact feeling first, then normalize it. Never say "I understand".
4. patternInsight: ONLY fill this if recent history exists AND you see a real pattern. Be specific with timing if possible (e.g. "Your mood tends to drop mid-week"). Leave empty string if no clear pattern.
5. activitySuggestion: MUST be exactly one of these options based on mood level:
   - Awful/Bad → "Box Breathing" or "Guided Meditation" or "Sleep Hygiene"
   - Okay → "Gratitude Journaling" or "Mindful Walk" or "Body Stretching"
   - Good/Great → "Creative Expression" or "Mindful Walk"
   Only return the activity name, nothing else.
6. activitySteps: Exactly 3 steps, each under 15 words, actionable and specific to the suggested activity.
7. reflectiveSummary: End with a forward-looking sentence. Under 50 words total.

Respond ONLY with valid JSON, no extra text:
{
  "emotionIntensity": 0.0,
  "triggerKeyword": "",
  "validation": "",
  "patternInsight": "",
  "activitySuggestion": "",
  "activityDuration": "",
  "activitySteps": "1. Step one\n2. Step two\n3. Step three",
  "reflectiveSummary": ""
}
''';

    try {
      final response = await http.post(
        Uri.parse("$_apiUrl?key=$_apiKey"),
        headers: {
          'Content-Type': 'application/json',
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
      );

        print("STATUS: ${response.statusCode}");
        print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final text = data['candidates'][0]['content']['parts'][0]['text'];

        final cleaned = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        return jsonDecode(cleaned);
      } else {
        print("ERROR BODY: ${response.body}");

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
      print("ERROR: $e");
      return fallbackResponse(mood);
    }
  }

  /// ✅ Weekly summary
  static Future<Map<String, dynamic>> generateWeeklySummary(
      List<DiaryEntry> entries) async {
    if (entries.isEmpty) {
      return _fallbackWeeklySummary(entries);
    }

    final entriesText = entries.map((e) {
      return '${e.createdAt.day}/${e.createdAt.month} | Mood: ${e.moodLabel} (${e.mood}) | "${e.entryText.substring(0, e.entryText.length.clamp(0, 100))}"';
    }).join('\n');

    final prompt = '''
You are a compassionate emotional wellness coach analyzing a user's diary from the past 7 days.
Your job is to think like a detective — find hidden patterns across time, not just summarize feelings.

Here are the diary entries in chronological order:
$entriesText

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
  "avgMoodScore": 0.0,
  "recurringTrigger": "",
  "sourceOfNegativity": "",
  "emotionalTrajectory": "improving | declining | fluctuating | stable",
  "weeklySummary": "",
  "hiddenInsight": "",
  "positiveStreak": 0,
  "negativeStreak": 0,
  "riskFlag": false,
  "riskMessage": ""
}

Notes:
- hiddenInsight: one surprising connection the user probably hasn't noticed themselves
- riskMessage: if riskFlag is true, suggest ONE gentle action (e.g., "Maybe reach out to someone you trust today")
- Keep weeklySummary under 80 words, personal and warm
''';

    try {
      final response = await http.post(
        Uri.parse("$_apiUrl?key=$_apiKey"),
        headers: {
          'Content-Type': 'application/json',
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final text = data['candidates'][0]['content']['parts'][0]['text'];

        final cleaned = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        return jsonDecode(cleaned);
      } else {
        return _fallbackWeeklySummary(entries);
      }
    } catch (e) {
      return _fallbackWeeklySummary(entries);
    }
  }

  
  
  static Map<String, dynamic> fallbackResponse(int mood) {
    final responses = [
      {
        'emotionIntensity': 8.5,
        'triggerKeyword': 'overwhelming stress',
        'validation':
            "It's completely okay to feel this way. You're navigating a lot right now.",
        'patternInsight': 'Your mood has been lower this week — be gentle with yourself.',
        'activitySuggestion': 'Box Breathing',
        'activityDuration': '5 min',
        'activitySteps': '1. Find a quiet space.\n2. Close your eyes and breathe deeply.\n3. Focus on the present moment for a few minutes.',
        'reflectiveSummary':
            'You showed up today even when things felt heavy. That takes courage.',
      },
      {
        'emotionIntensity': 6.5,
        'triggerKeyword': 'daily pressure',
        'validation': "Feeling down is a natural part of life. You are not alone in this.",
        'patternInsight': '',
        'activitySuggestion': 'Mindful Walk',
        'activityDuration': '10 min',
        'reflectiveSummary':
            'Every step forward counts, even the small ones. Keep going.',
      },
      {
        'emotionIntensity': 4.0,
        'triggerKeyword': 'routine',
        'validation': "Ordinary days have value too — rest is productive.",
        'patternInsight': '',
        'activitySuggestion': 'Gratitude Journaling',
        'activityDuration': '5 min',
        'reflectiveSummary':
            'Stable days build a strong foundation for better ones ahead.',
      },
      {
        'emotionIntensity': 3.0,
        'triggerKeyword': 'positive moments',
        'validation': "It's wonderful that you're feeling good today. Savour it!",
        'patternInsight': '',
        'activitySuggestion': 'Mindful Walk',
        'activityDuration': '15 min',
        'reflectiveSummary':
            'Your positive energy today is something to celebrate and build on.',
      },
      {
        'emotionIntensity': 1.5,
        'triggerKeyword': 'joy & connection',
        'validation': "You're radiating great energy — keep nurturing what brings you joy!",
        'patternInsight': '',
        'activitySuggestion': 'Creative Expression',
        'activityDuration': '20 min',
        'reflectiveSummary':
            'Great days like this remind us what we are working toward.',
      },
    ];
    return responses[mood.clamp(0, 4)];
  }

  static Map<String, dynamic> _fallbackWeeklySummary(List<DiaryEntry> entries) {
    final avg = entries.isEmpty
        ? 2.0
        : entries.map((e) => e.mood).reduce((a, b) => a + b) / entries.length;

    return {
      'dominantEmotion': avg >= 3 ? 'Content' : avg >= 2 ? 'Neutral' : 'Stressed',
      'avgMoodScore': avg,
      'recurringTrigger': 'daily routine',
      'sourceOfNegativity': '',
      'weeklySummary':
          'You have been consistently showing up and reflecting on your emotions this week.',
      'positiveStreak': 0,
      'negativeStreak': 0,
      'riskFlag': false,
      'riskMessage': '',
    };
  }


}