import 'package:flutter/material.dart';
import '../utils/transitions.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/diary_provider.dart';
import '../models/diary_entry.dart';
import 'mood_detail_screen.dart';
import 'weeklyReport_screen.dart';
import '../providers/activity_provider.dart';

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
      context.read<ActivityProvider>().forceRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    final activityProvider = context.watch<ActivityProvider>();
    final entries = provider.last7Days;
    final summary = provider.weeklySummary;
    final isLoading = provider.isLoadingWeekly;

    final moodCounts = List<int>.filled(5, 0);
    for (final e in entries) {
      moodCounts[e.mood.clamp(0, 4)]++;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('AI Insights'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => provider.loadWeeklySummary(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // // Risk alert
          // if (summary?['riskFlag'] == true) ...[
          //   _alertBanner(summary?['riskMessage'] as String?),
          //   const SizedBox(height: 16),
          // ],

          // Header stats
          Row(
            children: [
              _StatCard(
                label: 'Dominant\nMood',
                value: isLoading ? '...' : (summary?['dominantEmotion'] as String? ?? '—'),
                icon: Icons.mood,
                color: const Color(0xFFE1F5EE),
                iconColor: const Color(0xFF1D9E75),
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Avg\nScore',
                value: isLoading
                    ? '...'
                    : entries.isEmpty
                        ? '—'
                        : (entries.map((e) => e.mood).reduce((a, b) => a + b) /
                                entries.length)
                            .toStringAsFixed(1),
                icon: Icons.bar_chart,
                color: const Color(0xFFEEEDFE),
                iconColor: const Color(0xFF534AB7),
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Entries\nThis Week',
                value: entries.length.toString(),
                icon: Icons.book_outlined,
                color: const Color(0xFFFAEEDA),
                iconColor: const Color(0xFFBA7517),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 7-day mood trend LINE CHART
          if (entries.isNotEmpty) ...[
            _sectionTitle('7-Day Mood Trend'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
              ),
              child: SizedBox(
                height: 160,
                child: _MoodLineChart(entries: entries),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Mood distribution BAR CHART
          _sectionTitle('Mood Distribution'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
            ),
            child: SizedBox(
              height: 160,
              child: _MoodBarChart(moodCounts: moodCounts),
            ),
          ),
          const SizedBox(height: 20),

          // Top Activities donut chart
          _sectionTitle('Top Activities This Week'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
              ),
              child: activityProvider.top5Activities.isEmpty
                  ? _emptyCard('No activities logged this week yet!')
                  : SizedBox(
                      height: 200,
                      child: _ActivityDonutChart(activities: activityProvider.top5Activities),
                    ),
            ),
            const SizedBox(height: 20),


          // AI Summary card
          _sectionTitle('AI Weekly Summary'),
          const SizedBox(height: 10),
          if (isLoading)
            _loadingCard()
          else if (summary != null)
            _AiSummaryCard(summary: summary)
          else
            _emptyCard('No summary yet. Log entries and tap refresh!'),
          const SizedBox(height: 20),

          
          //const SizedBox(height: 32),

          // 在 Recent Entries 下面，SizedBox(height: 32) 之前加
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              slideRightRoute(const WeeklyReportScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF534AB7), Color(0xFF7B74D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('View Full AI Report',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text('Hidden insights · Trajectory · Triggers',
                            style: TextStyle(fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  // Widget _alertBanner(String? msg) => Container(
  //   padding: const EdgeInsets.all(14),
  //   decoration: BoxDecoration(
  //     color: const Color(0xFFFAECE7),
  //     borderRadius: BorderRadius.circular(14),
  //     border: Border.all(color: const Color(0xFFF5C4B3)),
  //   ),
  //   child: Row(
  //     children: [
  //       const Icon(Icons.warning_amber_outlined,
  //           color: Color(0xFF993C1D), size: 22),
  //       const SizedBox(width: 10),
  //       Expanded(
  //         child: Text(
  //           (msg == null || msg.trim().isEmpty)
  //               ? 'Your mood has been low recently. Please be gentle with yourself.'
  //               : msg,
  //           style: const TextStyle(
  //             fontSize: 12,
  //             color: Color(0xFF993C1D),
  //             height: 1.4,
  //           ),
  //         ),
  //       ),
  //     ],
  //   ),
  // );

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A2E)));

  Widget _loadingCard() => Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: const CircularProgressIndicator(color: Color(0xFF1D9E75)),
      );

  Widget _emptyCard(String msg) => Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF888780),
                height: 1.5)),
      );
}

// ─── Line Chart ─────────────────────────────────────────────────────────────

class _MoodLineChart extends StatelessWidget {
  final List<DiaryEntry> entries;
  const _MoodLineChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Build spots: sorted by date, x = days ago (0-6), y = mood (0-4)
    final now = DateTime.now();
    final spots = entries
        .map((e) {
          final daysAgo = now.difference(e.createdAt).inDays;
          return FlSpot((6 - daysAgo).toDouble(), e.mood.toDouble());
        })
        .where((s) => s.x >= 0 && s.x <= 6)
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][d.weekday % 7];
    });

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 4,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: const Color(0xFFF0F0F0),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                const emojis = ['😣','😞','😐','😊','😄'];
                final i = v.toInt();
                if (i < 0 || i > 4) return const SizedBox();
                return Text(emojis[i], style: const TextStyle(fontSize: 12));
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= dayLabels.length) return const SizedBox();
                return Text(dayLabels[i],
                    style: const TextStyle(
                        fontSize: 9, color: Color(0xFFB4B2A9)));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF1D9E75),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: const Color(0xFF1D9E75),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF1D9E75).withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bar Chart ───────────────────────────────────────────────────────────────

class _MoodBarChart extends StatelessWidget {
  final List<int> moodCounts;
  const _MoodBarChart({required this.moodCounts});

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFFE24B4A),
      Color(0xFFEF9F27),
      Color(0xFF888780),
      Color(0xFF1D9E75),
      Color(0xFF378ADD),
    ];
    const emojis = ['😣','😞','😐','😊','😄'];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (moodCounts.reduce((a, b) => a > b ? a : b) + 1).toDouble(),
        barTouchData: BarTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: const Color(0xFFF0F0F0), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFFB4B2A9)),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i > 4) return const SizedBox();
                return Text(emojis[i],
                    style: const TextStyle(fontSize: 16));
              },
            ),
          ),
        ),
        barGroups: List.generate(
          5,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: moodCounts[i].toDouble(),
                color: colors[i],
                width: 28,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (moodCounts.reduce((a, b) => a > b ? a : b) + 1).toDouble(),
                  color: const Color(0xFFF8F9FA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityDonutChart extends StatelessWidget {
  final Map<String, int> activities;
  const _ActivityDonutChart({required this.activities});

  static const _colors = [
    Color(0xFF1D9E75),
    Color(0xFF534AB7),
    Color(0xFFBA7517),
    Color(0xFF378ADD),
    Color(0xFF993C1D),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = activities.entries.toList();
    final total = entries.fold(0, (sum, e) => sum + e.value);

    return Row(
      children: [
        // 左侧图表部分
        Expanded(
          flex: 2, // 调小比例，让图表占位更少
          child: SizedBox(
            height: 100, // 限制高度，防止它过度膨胀
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 25, // 核心：调小中间空心 (原本是 40+)
                startDegreeOffset: -90,
                sections: List.generate(entries.length, (i) {
                  final pct = entries[i].value / total * 100;
                  return PieChartSectionData(
                    color: _colors[i % _colors.length],
                    value: entries[i].value.toDouble(),
                    title: '${pct.round()}%',
                    radius: 20, // 核心：调小圆环厚度 (原本是 48)
                    titleStyle: const TextStyle(
                      fontSize: 8, // 字也要变小
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    showTitle: pct > 20, // 只有比例够大才显示文字
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 右侧文字列表
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.map((e) {
              int index = entries.indexOf(e);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _colors[index % _colors.length],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF444441)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '×${e.value}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFFB4B2A9)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
// ─── AI Summary Card ─────────────────────────────────────────────────────────

class _AiSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _AiSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF1D9E75), size: 18),
              SizedBox(width: 8),
              Text('Summaries Report',
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
                fontSize: 13, color: Color(0xFF444441), height: 1.7),
          ),
          if ((summary['recurringTrigger'] as String?)?.isNotEmpty == true ||
              (summary['sourceOfNegativity'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if ((summary['sourceOfNegativity'] as String?)?.isNotEmpty == true)
                  Expanded(
                    child: _InfoChip(
                      label: 'Source of negativity',
                      value: summary['sourceOfNegativity'] as String,
                      color: const Color(0xFFFAECE7),
                      textColor: const Color(0xFF993C1D),
                    ),
                  ),
                if ((summary['sourceOfNegativity'] as String?)?.isNotEmpty == true &&
                    (summary['recurringTrigger'] as String?)?.isNotEmpty == true)
                  const SizedBox(width: 10),
                if ((summary['recurringTrigger'] as String?)?.isNotEmpty == true)
                  Expanded(
                    child: _InfoChip(
                      label: 'Triggers of bad mood',
                      value: summary['recurringTrigger'] as String? ?? '—',
                      color: const Color(0xFFFAEEDA),
                      textColor: const Color(0xFF633806),
                    ),
                  ),
              ],
            ),
          ],
        ],
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
    required this.label, required this.value,
    required this.color, required this.textColor,
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
                  fontSize: 9, color: Color(0xFF888780), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
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
  const _StatCard({
    required this.label, required this.value, required this.icon,
    required this.color, required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 9, color: Color(0xFF888780))),
          ],
        ),
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
                Text(entry.entryText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1A1A2E),
                        height: 1.4)),
                const SizedBox(height: 4),
                Text(_timeAgo(entry.createdAt),
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFFB4B2A9))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFFB4B2A9)),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
