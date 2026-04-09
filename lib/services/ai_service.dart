import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/diary_entry.dart';

class AiService {
  // Replace with your actual API key and endpoint
  // For production: use Claude API (Anthropic) or OpenAI
  static const String _apiKey = 'YOUR_API_KEY_HERE';
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  /// Analyzes a single diary entry and returns AI reflection + emotion data
  static Future<Map<String, dynamic>> analyzeDiaryEntry({
    required String entryText,
    required int mood,
    required List<DiaryEntry> recentEntries,
  }) async {
    final moodLabels = ['Awful', 'Bad', 'Okay', 'Good', 'Great'];
    final currentMoodLabel = moodLabels[mood.clamp(0, 4)];

    // Build context from recent entries (last 7 days)
    final historyContext = recentEntries.take(7).map((e) {
      return '- ${e.createdAt.day}/${e.createdAt.month}: Mood=${e.moodLabel}, Entry="${e.entryText.substring(0, e.entryText.length.clamp(0, 80))}..."';
    }).join('\n');

    final prompt = '''
You are a compassionate emotional wellness assistant. Analyze this diary entry and recent history, then respond ONLY with valid JSON.

Current Entry:
- Mood: $currentMoodLabel
- Text: "$entryText"

Recent History (last 7 days):
${historyContext.isEmpty ? 'No previous entries.' : historyContext}

Respond with this exact JSON structure:
{
  "emotionIntensity": <float 0.0-10.0>,
  "triggerKeyword": "<1-3 word trigger e.g. work stress, family, sleep>",
  "validation": "<1-2 warm sentences acknowledging feelings>",
  "patternInsight": "<1 sentence about a pattern noticed from history, or empty string if no history>",
  "activitySuggestion": "<one specific activity e.g. Box Breathing, Mindful Walk, Journaling Prompt>",
  "activityDuration": "<e.g. 5 min, 10 min>",
  "reflectiveSummary": "<2-3 sentence supportive summary>"
}
''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        // Strip markdown code fences if present
        final cleaned = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        return jsonDecode(cleaned) as Map<String, dynamic>;
      } else {
        return _fallbackResponse(mood);
      }
    } catch (e) {
      return _fallbackResponse(mood);
    }
  }

  /// Generates weekly AI insight summary
  static Future<Map<String, dynamic>> generateWeeklySummary(
      List<DiaryEntry> entries) async {
    if (entries.isEmpty) {
      return {
        'dominantEmotion': 'No data',
        'avgMoodScore': 0,
        'recurringTrigger': 'None',
        'weeklySummary':
            'Start journaling to get your weekly AI insight summary!',
        'positiveStreak': 0,
        'negativeStreak': 0,
        'riskFlag': false,
      };
    }

    final entriesText = entries.map((e) {
      return '${e.createdAt.day}/${e.createdAt.month} | Mood: ${e.moodLabel} (${e.mood}) | "${e.entryText.substring(0, e.entryText.length.clamp(0, 100))}"';
    }).join('\n');

    final prompt = '''
You are a compassionate emotional wellness coach. Analyze these diary entries from the past week and respond ONLY with valid JSON.

Diary Entries:
$entriesText

Respond with this exact JSON structure:
{
  "dominantEmotion": "<most common emotion e.g. Anxious, Content, Stressed>",
  "avgMoodScore": <float 0.0-4.0>,
  "recurringTrigger": "<main trigger e.g. work deadlines, social interactions>",
  "sourceOfNegativity": "<brief phrase or empty string>",
  "weeklySummary": "<3-4 warm, supportive sentences summarizing the week and growth>",
  "positiveStreak": <int, consecutive good/great days>,
  "negativeStreak": <int, consecutive awful/bad days>,
  "riskFlag": <true if 3+ consecutive low mood days>,
  "riskMessage": "<if riskFlag true: gentle supportive message, else empty string>"
}
''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 600,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        final cleaned = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        return jsonDecode(cleaned) as Map<String, dynamic>;
      } else {
        return _fallbackWeeklySummary(entries);
      }
    } catch (e) {
      return _fallbackWeeklySummary(entries);
    }
  }

  // ── Fallback responses when API is unavailable ──────────────────────────────

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
            'Great days like this remind us what we are working toward. Hold onto this feeling.',
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
          'You have been consistently showing up and reflecting on your emotions this week. That self-awareness is a powerful tool for growth.',
      'positiveStreak': 0,
      'negativeStreak': 0,
      'riskFlag': false,
      'riskMessage': '',
    };
  }
}
