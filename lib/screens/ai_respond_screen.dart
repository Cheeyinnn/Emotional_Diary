import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/diary_entry.dart';
import '../utils/transitions.dart';
import '../utils/activityRouter.dart';
import '../providers/diary_provider.dart';
import 'home_screen.dart';
import 'weeklyReport_screen.dart';

class AiRespondScreen extends StatelessWidget {
  final DiaryEntry entry;
  final Map<String, dynamic> aiData;

  const AiRespondScreen({
    super.key,
    required this.entry,
    required this.aiData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('AI Respond'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            fadeScaleRoute(const HomeScreen()),
            (r) => false,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(child: _buildContent(context)),
    );
  }

  Widget _buildContent(BuildContext context) {
    final ai = aiData;
    final intensity = (ai['emotionIntensity'] as num?)?.toDouble() ?? 5.0;
    final duration = ai['activityDuration'] as String?;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // AI Avatar
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE1F5EE),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF1D9E75).withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Color(0xFF1D9E75), size: 30),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text('AI RESPOND',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF888780),
                  letterSpacing: 1.5)),
        ),
        const SizedBox(height: 24),

        // Emotional Validation
        _bubble(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(entry.moodEmoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text('Feeling ${entry.moodLabel}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: entry.moodColor)),
                ],
              ),
              const SizedBox(height: 10),
              Text(ai['validation'] as String? ?? '',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                      height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Emotion Intensity
        _bubble(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Emotion Intensity',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF888780))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: intensity / 10.0,
                        backgroundColor: const Color(0xFFF0F0F0),
                        valueColor: AlwaysStoppedAnimation(
                            intensity > 7
                                ? const Color(0xFFE24B4A)
                                : intensity > 4
                                    ? const Color(0xFFEF9F27)
                                    : const Color(0xFF1D9E75)),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${intensity.toStringAsFixed(1)}/10',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                ],
              ),
              if (ai['triggerKeyword'] != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAEEDA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('# ${ai['triggerKeyword']}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF633806),
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Pattern Insight
        if ((ai['patternInsight'] as String?)?.isNotEmpty == true) ...[
          _bubble(
            accent: const Color(0xFFEEEDFE),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.query_stats,
                    color: Color(0xFF534AB7), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pattern Noticed',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF534AB7))),
                      const SizedBox(height: 4),
                      Text(ai['patternInsight'] as String,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF3C3489),
                              height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Activity Suggestion
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1D9E75),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('RECOMMENDED ACTIVITY',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ai['activitySuggestion'] as String? ?? 'Box Breathing',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ActivityRouter.navigate(
                      context,
                      ai['activitySuggestion'] as String? ?? 'Box Breathing',
                      duration: ai['activityDuration'] as String?,
                      steps: ai['activitySteps'] as String?,  // 新增

                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
              if (duration != null && duration.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(duration,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8))),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Reflection
        _bubble(
          accent: const Color(0xFFE8F7F2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reflection',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D9E75))),
              const SizedBox(height: 6),
              Text(ai['reflectiveSummary'] as String? ?? '',
                  style: const TextStyle(
                      fontSize: 14, height: 1.6, color: Color(0xFF1A1A2E))),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 在 Skip for Now 按钮上面加
          Consumer<DiaryProvider>(
            builder: (context, provider, _) {
              if (!provider.shouldShowWeeklySummary) return const SizedBox();
              return GestureDetector(
                onTap: () => Navigator.of(context).pushAndRemoveUntil(
                  fadeScaleRoute(const WeeklyReportScreen()),
                  (r) => false,
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEDFE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFAFA9EC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.insights, color: Color(0xFF534AB7), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your Weekly Insights are ready!',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3C3489))),
                            SizedBox(height: 2),
                            Text('See your mood patterns & AI summary',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF534AB7))),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: Color(0xFF534AB7), size: 16),
                    ],
                  ),
                ),
              );
            },
          ),

        


        // Skip button
        TextButton(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            fadeScaleRoute(const HomeScreen()),
            (r) => false,
          ),
          child: const Text('Skip for Now',
              style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888780),
                  fontWeight: FontWeight.w500)),
        ),

        
      ],
    );
  }

  Widget _bubble({required Widget child, Color? accent}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent ?? const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: child,
    );
  }
}