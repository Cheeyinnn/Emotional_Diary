import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/diary_entry.dart';

class AiService {

  static const String _apiKey = 'AIzaSyDfkTy9gfhX6F8iWKcA1Pq-oB4irKyPwCQ';

  // Gemini endpoint
  static const String _apiUrl =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

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
You are a compassionate emotional wellness assistant. Analyze this diary entry and recent history, then respond ONLY with valid JSON.

Current Entry:
- Mood: $currentMoodLabel
- Text: "$entryText"

Recent History:
${historyContext.isEmpty ? 'No previous entries.' : historyContext}

Return JSON:
{
  "emotionIntensity": 0.0,
  "triggerKeyword": "",
  "validation": "",
  "patternInsight": "",
  "activitySuggestion": "",
  "activityDuration": "",
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
            ..._fallbackResponse(mood),
            'isFallback': true,
            'error': 'quota_exceeded',
          };
        }

        return _fallbackResponse(mood);
      }
    } catch (e) {
      print("ERROR: $e");
      return _fallbackResponse(mood);
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
You are a compassionate emotional wellness coach. Analyze these diary entries and respond ONLY in JSON.

$entriesText

Return JSON:
{
  "dominantEmotion": "",
  "avgMoodScore": 0.0,
  "recurringTrigger": "",
  "sourceOfNegativity": "",
  "weeklySummary": "",
  "positiveStreak": 0,
  "negativeStreak": 0,
  "riskFlag": false,
  "riskMessage": ""
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

  static Map<String, dynamic> _fallbackResponse(int mood) {
    final responses = [
      {
        'emotionIntensity': 8.5,
        'triggerKeyword': 'overwhelming stress',
        'validation':
            "It's completely okay to feel this way. You're navigating a lot right now.",
        'patternInsight': 'Your mood has been lower this week — be gentle with yourself.',
        'activitySuggestion': 'Box Breathing',
        'activityDuration': '5 min',
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