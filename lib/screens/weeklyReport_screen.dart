import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../models/diary_entry.dart';
import '../utils/transitions.dart';
import 'home_screen.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  
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
    final summary = provider.weeklySummary;
    final isLoading = provider.isLoadingWeekly;
    final entries = provider.last7Days;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Weekly AI Report',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => provider.loadWeeklySummary(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? _buildLoading()
          : summary == null
              ? _buildEmpty()
              : _buildContent(context, summary, entries),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF1D9E75)),
          const SizedBox(height: 16),
          Text(
            'Analyzing your week...',
            style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF888780),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.insights,
                  color: Color(0xFF1D9E75), size: 34),
            ),
            const SizedBox(height: 20),
            const Text(
              'No report yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Log at least a few entries this week\nand tap refresh to generate your report.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF888780), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────
  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> summary,
    List<DiaryEntry> entries,
  ) {
    final trajectory =
        summary['emotionalTrajectory'] as String? ?? 'fluctuating';
    final riskFlag = summary['riskFlag'] as bool? ?? false;
    final hiddenInsight = summary['hiddenInsight'] as String? ?? '';
    final weeklySummary = summary['weeklySummary'] as String? ?? '';
    final recurringTrigger = summary['recurringTrigger'] as String? ?? '';
    final sourceOfNegativity = summary['sourceOfNegativity'] as String? ?? '';
    final riskMessage = summary['riskMessage'] as String? ?? '';
    final positiveStreak = summary['positiveStreak'] as int? ?? 0;
    final negativeStreak = summary['negativeStreak'] as int? ?? 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Date range header ────────────────────────────────────────────────
        _dateRangeHeader(entries),
        const SizedBox(height: 20),

        // ── Risk Alert ───────────────────────────────────────────────────────
        if (riskFlag && riskMessage.isNotEmpty) ...[
          _riskBanner(riskMessage),
          const SizedBox(height: 16),
        ],

        // ── Emotional Trajectory ─────────────────────────────────────────────
        _trajectoryCard(trajectory, positiveStreak, negativeStreak),
        const SizedBox(height: 16),

        // ── Hidden Insight (hero card) ───────────────────────────────────────
        if (hiddenInsight.isNotEmpty) ...[
          _hiddenInsightCard(hiddenInsight),
          const SizedBox(height: 16),
        ],

        // ── Weekly Summary ───────────────────────────────────────────────────
        _sectionLabel('YOUR WEEK IN WORDS'),
        const SizedBox(height: 10),
        _weeklySummaryCard(weeklySummary),
        const SizedBox(height: 16),

        // ── Triggers & Negativity ────────────────────────────────────────────
        if (recurringTrigger.isNotEmpty || sourceOfNegativity.isNotEmpty) ...[
          _sectionLabel('WHAT AFFECTED YOU'),
          const SizedBox(height: 10),
          Row(
            children: [
              if (sourceOfNegativity.isNotEmpty)
                Expanded(
                  child: _infoChip(
                    icon: Icons.cloud_outlined,
                    label: 'Source of Negativity',
                    value: sourceOfNegativity,
                    bgColor: const Color(0xFFFAECE7),
                    textColor: const Color(0xFF993C1D),
                    iconColor: const Color(0xFFE24B4A),
                  ),
                ),
              if (sourceOfNegativity.isNotEmpty && recurringTrigger.isNotEmpty)
                const SizedBox(width: 10),
              if (recurringTrigger.isNotEmpty)
                Expanded(
                  child: _infoChip(
                    icon: Icons.repeat_outlined,
                    label: 'Recurring Trigger',
                    value: recurringTrigger,
                    bgColor: const Color(0xFFFAEEDA),
                    textColor: const Color(0xFF633806),
                    iconColor: const Color(0xFFEF9F27),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // ── Streak summary ───────────────────────────────────────────────────
        _streakRow(positiveStreak, negativeStreak),
        const SizedBox(height: 32),

        // ── Back to home ─────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              fadeScaleRoute(const HomeScreen()),
              (r) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27)),
              elevation: 0,
            ),
            child: const Text(
              'Back to Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _dateRangeHeader(List<DiaryEntry> entries) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final range =
        '${weekAgo.day} ${months[weekAgo.month - 1]} — ${now.day} ${months[now.month - 1]}';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F5EE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: Color(0xFF1D9E75)),
              const SizedBox(width: 6),
              Text(
                range,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D9E75)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF888780)),
        ),
      ],
    );
  }

  Widget _riskBanner(String msg) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAECE7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF5C4B3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.favorite_border,
                color: Color(0xFF993C1D), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF993C1D),
                    height: 1.5),
              ),
            ),
          ],
        ),
      );

  Widget _trajectoryCard(
      String trajectory, int positiveStreak, int negativeStreak) {
    final config = _trajectoryConfig(trajectory);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config['bgColor'] as Color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (config['iconColor'] as Color).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (config['iconColor'] as Color).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(config['icon'] as IconData,
                color: config['iconColor'] as Color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emotional Trajectory',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: (config['iconColor'] as Color).withOpacity(0.7),
                      letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                Text(
                  config['label'] as String,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: config['iconColor'] as Color),
                ),
                const SizedBox(height: 2),
                Text(
                  config['description'] as String,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF888780), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _trajectoryConfig(String trajectory) {
    switch (trajectory.toLowerCase()) {
      case 'improving':
        return {
          'bgColor': const Color(0xFFE1F5EE),
          'iconColor': const Color(0xFF1D9E75),
          'icon': Icons.trending_up,
          'label': 'Improving 📈',
          'description': 'Your mood has been getting better this week.',
        };
      case 'declining':
        return {
          'bgColor': const Color(0xFFFAECE7),
          'iconColor': const Color(0xFFE24B4A),
          'icon': Icons.trending_down,
          'label': 'Declining 📉',
          'description': 'Your mood has been dipping — be gentle with yourself.',
        };
      case 'stable':
        return {
          'bgColor': const Color(0xFFEEEDFE),
          'iconColor': const Color(0xFF534AB7),
          'icon': Icons.trending_flat,
          'label': 'Stable 😌',
          'description': 'Your mood has been consistent and steady.',
        };
      default: // fluctuating
        return {
          'bgColor': const Color(0xFFFAEEDA),
          'iconColor': const Color(0xFFEF9F27),
          'icon': Icons.show_chart,
          'label': 'Fluctuating 🌊',
          'description': 'Your mood has had some ups and downs this week.',
        };
    }
  }

  Widget _hiddenInsightCard(String insight) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF534AB7), Color(0xFF7B74D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '✨  HIDDEN INSIGHT',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.6,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'A pattern you might not have noticed yourself.',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.65),
                  height: 1.4),
            ),
          ],
        ),
      );

  Widget _weeklySummaryCard(String text) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: Color(0xFF1D9E75), size: 16),
                const SizedBox(width: 8),
                const Text(
                  'From your AI companion',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D9E75)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                  height: 1.7),
            ),
          ],
        ),
      );

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
  }) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: iconColor),
                const SizedBox(width: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF888780),
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.4)),
          ],
        ),
      );

  Widget _streakRow(int positive, int negative) => Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('😊', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(
                    '$positive ${positive == 1 ? 'day' : 'days'}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D9E75)),
                  ),
                  const Text(
                    'positive streak',
                    style:
                        TextStyle(fontSize: 10, color: Color(0xFF888780)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAECE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('😞', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(
                    '$negative ${negative == 1 ? 'day' : 'days'}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE24B4A)),
                  ),
                  const Text(
                    'negative streak',
                    style:
                        TextStyle(fontSize: 10, color: Color(0xFF888780)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF888780),
            letterSpacing: 1.2),
      );
}