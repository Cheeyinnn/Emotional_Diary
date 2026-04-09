import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../models/diary_entry.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().loadWeeklySummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    final entries = provider.last7Days;
    final summary = provider.weeklySummary;
    final isLoading = provider.isLoadingWeekly;

    // Mood distribution count
    final moodCounts = List<int>.filled(5, 0);
    for (final e in entries) {
      moodCounts[e.mood.clamp(0, 4)]++;
    }
    final maxCount = moodCounts.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('AI Insights'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => provider.loadWeeklySummary(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Risk alert
          if (summary?['riskFlag'] == true) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAECE7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF5C4B3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      color: Color(0xFF993C1D), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      summary?['riskMessage'] as String? ??
                          'Your mood has worsened recently. Please be gentle with yourself.',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF993C1D),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Weekly header
          const Text('This Week',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          Text('${entries.length} entries logged',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF888780))),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _StatCard(
                label: 'Dominant Mood',
                value: isLoading
                    ? '...'
                    : (summary?['dominantEmotion'] as String? ?? '—'),
                icon: Icons.mood,
                color: const Color(0xFFE1F5EE),
                iconColor: const Color(0xFF1D9E75),
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Avg Score',
                value: isLoading
                    ? '...'
                    : ((summary?['avgMoodScore'] as num?)?.toStringAsFixed(1) ??
                        '—'),
                icon: Icons.bar_chart,
                color: const Color(0xFFEEEDFE),
                iconColor: const Color(0xFF534AB7),
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Main Trigger',
                value: isLoading
                    ? '...'
                    : (summary?['recurringTrigger'] as String? ?? '—'),
                icon: Icons.bolt_outlined,
                color: const Color(0xFFFAEEDA),
                iconColor: const Color(0xFFBA7517),
                small: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Mood distribution bar chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFE0E0E0), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your statistics',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(5, (i) {
                    final labels = ['Awful', 'Bad', 'Okay', 'Good', 'Great'];
                    final emojis = ['😣', '😞', '😐', '😊', '😄'];
                    final colors = [
                      const Color(0xFFE24B4A),
                      const Color(0xFFEF9F27),
                      const Color(0xFF888780),
                      const Color(0xFF1D9E75),
                      const Color(0xFF378ADD),
                    ];
                    final count = moodCounts[i];
                    final barH = maxCount == 0
                        ? 0.0
                        : (count / maxCount) * 80.0;

                    return Column(
                      children: [
                        Text(count.toString(),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          width: 36,
                          height: barH > 0 ? barH : 4,
                          decoration: BoxDecoration(
                            color: count > 0
                                ? colors[i]
                                : const Color(0xFFF0F0F0),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(emojis[i],
                            style: const TextStyle(fontSize: 16)),
                        Text(labels[i],
                            style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFFB4B2A9))),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // AI Summary
          if (isLoading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFF1D9E75)),
            ))
          else if (summary != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFE0E0E0), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Color(0xFF1D9E75), size: 18),
                      const SizedBox(width: 8),
                      const Text('AI Generated Summary',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    summary['weeklySummary'] as String? ?? '',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF444441),
                        height: 1.7),
                  ),
                  if ((summary['sourceOfNegativity'] as String?)
                          ?.isNotEmpty ==
                      true) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoChip(
                            label: 'Source of negativity',
                            value: summary['sourceOfNegativity'] as String,
                            color: const Color(0xFFFAECE7),
                            textColor: const Color(0xFF993C1D),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoChip(
                            label: 'Triggers of bad mood',
                            value: summary['recurringTrigger'] as String? ??
                                '—',
                            color: const Color(0xFFFAEEDA),
                            textColor: const Color(0xFF633806),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recent entries list
          if (entries.isNotEmpty) ...[
            const Text('Recent Entries',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 12),
            ...entries.take(5).map((e) => _EntryTile(entry: e)),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.book_outlined,
                        size: 48, color: Color(0xFFD3D1C7)),
                    const SizedBox(height: 12),
                    const Text('No entries this week',
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFF888780))),
                    const SizedBox(height: 4),
                    const Text('Start journaling to see your AI insights',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFFB4B2A9))),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final bool small;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.iconColor,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: small ? 11 : 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: Color(0xFF888780))),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF888780),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final DiaryEntry entry;
  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: entry.moodColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
                child: Text(entry.moodEmoji,
                    style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.entryText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A1A2E),
                      height: 1.4),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(entry.createdAt),
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFFB4B2A9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
