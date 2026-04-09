import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import '../services/ai_service.dart';
import 'home_screen.dart';

class AiRespondScreen extends StatefulWidget {
  final DiaryEntry entry;
  const AiRespondScreen({super.key, required this.entry});

  @override
  State<AiRespondScreen> createState() => _AiRespondScreenState();
}

class _AiRespondScreenState extends State<AiRespondScreen> {
  Map<String, dynamic>? _aiData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAiResponse();
  }

  Future<void> _loadAiResponse() async {
    final provider = context.read<DiaryProvider>();
    final recent = provider.last7Days
        .where((e) => e.id != widget.entry.id)
        .toList();

    final result = await AiService.analyzeDiaryEntry(
      entryText: widget.entry.entryText,
      mood: widget.entry.mood,
      recentEntries: recent,
    );

    if (mounted) {
      setState(() {
        _aiData = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('AI Respond'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
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
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _buildContent(entry),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1D9E75)),
          SizedBox(height: 20),
          Text('Analyzing your entry...',
              style: TextStyle(color: Color(0xFF888780), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildContent(DiaryEntry entry) {
    final ai = _aiData!;
    final intensity = (ai['emotionIntensity'] as num?)?.toDouble() ?? 5.0;

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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      ai['activitySuggestion'] as String? ??
                          'Box Breathing',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(ai['activityDuration'] as String? ?? '5 min',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withOpacity(0.8))),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Skip button
        TextButton(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
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
