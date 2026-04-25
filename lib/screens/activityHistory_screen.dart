import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../models/activity_log.dart';

// ── Filter enum ───────────────────────────────────────────────────────────────

enum _Filter { today, thisWeek, thisMonth, thisYear }

extension _FilterLabel on _Filter {
  String get label {
    switch (this) {
      case _Filter.today:
        return 'Today';
      case _Filter.thisWeek:
        return 'This Week';
      case _Filter.thisMonth:
        return 'This Month';
      case _Filter.thisYear:
        return 'This Year';
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  _Filter _activeFilter = _Filter.thisWeek;

  List<ActivityLog> _logsFor(ActivityProvider provider) {
    switch (_activeFilter) {
      case _Filter.today:
        return provider.logsToday;
      case _Filter.thisWeek:
        return provider.logsThisWeek;
      case _Filter.thisMonth:
        return provider.logsThisMonth;
      case _Filter.thisYear:
        return provider.logsThisYear;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Activity History',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, provider, _) {
          final allLogs = _logsFor(provider);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Stats Section ──────────────────────────────────────────────
              _buildStats(provider),
              const SizedBox(height: 28),

              // ── Filter Tabs ────────────────────────────────────────────────
              const Text(
                'ALL ACTIVITY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF888780),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              _buildFilterTabs(),
              const SizedBox(height: 16),

              // ── History Section ────────────────────────────────────────────
              if (allLogs.isEmpty)
                _buildEmptyFilter()
              else
                ..._buildGroupedLogs(allLogs, provider),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  // ── Filter Tabs ────────────────────────────────────────────────────────────

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _Filter.values.map((filter) {
          final isActive = _activeFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF1D9E75)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF1D9E75)
                      : const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              child: Text(
                filter.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF888780),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Grouped Logs ───────────────────────────────────────────────────────────

  List<Widget> _buildGroupedLogs(
      List<ActivityLog> logs, ActivityProvider provider) {
    final grouped = _groupByDate(logs);
    final entries = grouped.entries.toList();

    return entries.mapIndexed((index, entry) {
      final isInitiallyExpanded = index == 0;
      return _DateGroupTile(
        dateKey: entry.key,
        logs: entry.value,
        isInitiallyExpanded: isInitiallyExpanded,
        onDelete: (id) => provider.deleteLog(id),
      );
    }).toList();
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  Widget _buildStats(ActivityProvider provider) {
    final topActivity = provider.topActivityThisWeek;
    final top5 = provider.top5Activities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top stat row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline,
                label: 'This Week',
                value: '${provider.completedThisWeek}',
                unit: provider.completedThisWeek == 1 ? 'session' : 'sessions',
                color: const Color(0xFF1D9E75),
                bg: const Color(0xFFE1F5EE),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.history,
                label: 'All Time',
                value: '${provider.totalCompleted}',
                unit: provider.totalCompleted == 1 ? 'session' : 'sessions',
                color: const Color(0xFF534AB7),
                bg: const Color(0xFFEEEDFE),
              ),
            ),
          ],
        ),

        // Top activity badge
        if (topActivity != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _activityBgColor(topActivity),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _activityIcon(topActivity),
                    color: _activityIconColor(topActivity),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top pick this week',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF888780),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        topActivity,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          size: 10, color: Color(0xFFBA7517)),
                      SizedBox(width: 3),
                      Text(
                        'Favourite',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFBA7517),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Top 5 breakdown
        if (top5.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'THIS WEEK BREAKDOWN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF888780),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
            ),
            child: Column(
              children: top5.entries.map((e) {
                final maxCount =
                    top5.values.reduce((a, b) => a > b ? a : b);
                final fraction = e.value / maxCount;
                final color = _activityIconColor(e.key);
                final bg = _activityBgColor(e.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration:
                            BoxDecoration(color: bg, shape: BoxShape.circle),
                        child:
                            Icon(_activityIcon(e.key), color: color, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.key,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: fraction,
                                minHeight: 5,
                                backgroundColor: const Color(0xFFF0F0F0),
                                valueColor: AlwaysStoppedAnimation(color),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${e.value}×',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // ── Empty filter state ─────────────────────────────────────────────────────

  Widget _buildEmptyFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFE1F5EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.spa, color: Color(0xFF1D9E75), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'No activities ${_activeFilter.label.toLowerCase()}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Complete a wellness activity to\nsee it appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF888780),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, List<ActivityLog>> _groupByDate(List<ActivityLog> logs) {
    final map = <String, List<ActivityLog>>{};
    for (final log in logs) {
      final key =
          '${log.completedAt.year}-${log.completedAt.month.toString().padLeft(2, '0')}-${log.completedAt.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(log);
    }
    return map;
  }
}

// ── mapIndexed extension ──────────────────────────────────────────────────────

extension _IndexedIterable<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T element) f) sync* {
    var index = 0;
    for (final element in this) {
      yield f(index++, element);
    }
  }
}

// ── Date Group Tile ───────────────────────────────────────────────────────────

class _DateGroupTile extends StatefulWidget {
  final String dateKey;
  final List<ActivityLog> logs;
  final bool isInitiallyExpanded;
  final void Function(String id) onDelete;

  const _DateGroupTile({
    required this.dateKey,
    required this.logs,
    required this.isInitiallyExpanded,
    required this.onDelete,
  });

  @override
  State<_DateGroupTile> createState() => _DateGroupTileState();
}

class _DateGroupTileState extends State<_DateGroupTile> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isInitiallyExpanded;
  }

  String _formatGroupDate(String key) {
    final parts = key.split('-');
    final date = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8, top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatGroupDate(widget.dateKey),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.logs.length} ${widget.logs.length == 1 ? 'session' : 'sessions'}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D9E75),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Color(0xFF888780),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Expandable content ─────────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _expanded
              ? Column(
                  children: widget.logs
                      .map((log) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ActivityLogTile(
                              log: log,
                              onDelete: () => widget.onDelete(log.id),
                            ),
                          ))
                      .toList(),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Activity Log Tile ─────────────────────────────────────────────────────────

class _ActivityLogTile extends StatelessWidget {
  final ActivityLog log;
  final VoidCallback onDelete;

  const _ActivityLogTile({
    required this.log,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _activityIcon(log.activityName);
    final color = _activityIconColor(log.activityName);
    final bg = _activityBgColor(log.activityName);
    final hasContent =
        log.userContent != null && log.userContent!.trim().isNotEmpty;

    return GestureDetector(
      onTap: hasContent ? () => _showContentDetail(context) : null,
      child: Container(
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
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.activityName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // ── Date + time row ──────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 10, color: Color(0xFFB4B2A9)),
                      const SizedBox(width: 3),
                      Text(
                        _formatDate(log.completedAt),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF888780)),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time,
                          size: 10, color: Color(0xFFB4B2A9)),
                      const SizedBox(width: 3),
                      Text(
                        _formatTime(log.completedAt),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF888780)),
                      ),
                      if (hasContent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Has notes',
                            style: TextStyle(
                                fontSize: 9,
                                color: color,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (hasContent)
              const Icon(Icons.chevron_right,
                  size: 16, color: Color(0xFFB4B2A9)),
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.delete_outline,
                    size: 18, color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContentDetail(BuildContext context) {
    final isGratitude = log.activityName.toLowerCase().contains('gratitude');
    final isCreative = log.activityName.toLowerCase().contains('creative');

    String? creativePrompt;
    List<String> parts;

    if (isCreative && log.userContent != null) {
      final splitByPromptSep = log.userContent!.split('|||');
      if (splitByPromptSep.length >= 2) {
        creativePrompt = splitByPromptSep[0].trim();
        parts = [splitByPromptSep.sublist(1).join('|||').trim()];
      } else {
        creativePrompt = null;
        parts = [log.userContent!];
      }
    } else {
      parts = log.userContent!.split(' | ');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContentDetailSheet(
        activityName: log.activityName,
        completedAt: log.completedAt,
        parts: parts,
        isGratitude: isGratitude,
        isCreative: isCreative,
        creativePrompt: creativePrompt,
        color: _activityIconColor(log.activityName),
        bg: _activityBgColor(log.activityName),
        icon: _activityIcon(log.activityName),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete activity?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Remove "${log.activityName}" from your history?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF888780)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888780))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFE24B4A))),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }
}

// ── Content Detail Bottom Sheet ───────────────────────────────────────────────

class _ContentDetailSheet extends StatelessWidget {
  final String activityName;
  final DateTime completedAt;
  final List<String> parts;
  final bool isGratitude;
  final bool isCreative;
  final String? creativePrompt;
  final Color color;
  final Color bg;
  final IconData icon;

  const _ContentDetailSheet({
    required this.activityName,
    required this.completedAt,
    required this.parts,
    required this.isGratitude,
    required this.isCreative,
    this.creativePrompt,
    required this.color,
    required this.bg,
    required this.icon,
  });

  static const _gratitudePrompts = [
    'Something that made you smile…',
    'A person you are grateful for…',
    'A small thing you often overlook…',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activityName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      _formatDate(completedAt),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF888780)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isGratitude)
            ...List.generate(parts.length, (i) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bg.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (i < _gratitudePrompts.length)
                      Text(
                        _gratitudePrompts[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      parts[i],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1A1A2E),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            })
          else if (isCreative)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (creativePrompt != null && creativePrompt!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: color.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline,
                                color: color, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'PROMPT',
                              style: TextStyle(
                                fontSize: 9,
                                color: color,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          creativePrompt!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1A1A2E),
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFE0E0E0), width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR RESPONSE',
                        style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        parts.join('\n'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bg.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                parts.join('\n'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                  height: 1.7,
                ),
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              child: const Text('Close',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} · $hour:$m $period';
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

IconData _activityIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('breath')) return Icons.air;
  if (n.contains('walk')) return Icons.directions_walk;
  if (n.contains('meditat')) return Icons.self_improvement;
  if (n.contains('gratitude') || n.contains('journal')) return Icons.edit_note;
  if (n.contains('creative')) return Icons.brush_outlined;
  if (n.contains('sleep')) return Icons.bedtime_outlined;
  if (n.contains('stretch')) return Icons.accessibility_new;
  return Icons.spa;
}

Color _activityIconColor(String name) {
  final n = name.toLowerCase();
  if (n.contains('breath')) return const Color(0xFF1D9E75);
  if (n.contains('meditat')) return const Color(0xFF534AB7);
  if (n.contains('sleep')) return const Color(0xFF378ADD);
  if (n.contains('walk')) return const Color(0xFF5A8A2F);
  if (n.contains('stretch')) return const Color(0xFFEF9F27);
  if (n.contains('gratitude') || n.contains('journal'))
    return const Color(0xFFBA7517);
  if (n.contains('creative')) return const Color(0xFFE24B4A);
  return const Color(0xFF1D9E75);
}

Color _activityBgColor(String name) {
  final n = name.toLowerCase();
  if (n.contains('breath')) return const Color(0xFFE1F5EE);
  if (n.contains('meditat')) return const Color(0xFFEEEDFE);
  if (n.contains('sleep')) return const Color(0xFFDDEEFA);
  if (n.contains('walk')) return const Color(0xFFEAF3DE);
  if (n.contains('stretch')) return const Color(0xFFFAEEDA);
  if (n.contains('gratitude') || n.contains('journal'))
    return const Color(0xFFFAEEDA);
  if (n.contains('creative')) return const Color(0xFFFAECE7);
  return const Color(0xFFE1F5EE);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color bg;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF888780),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}