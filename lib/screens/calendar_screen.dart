import 'package:flutter/material.dart';
import '../utils/transitions.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../models/diary_entry.dart';
import 'mood_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();

  void _prevMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1));

  void _nextMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1));

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    final entries = provider.entries;
    final monthName = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ][_focusedMonth.month - 1];

    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startOffset = firstDay.weekday % 7;

    final monthEntries = entries.where((e) =>
        e.createdAt.year == _focusedMonth.year &&
        e.createdAt.month == _focusedMonth.month).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Calendar'), backgroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _prevMonth),
                    Text('$monthName ${_focusedMonth.year}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E))),
                    IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _nextMonth),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(d,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFB4B2A9))),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: startOffset + lastDay.day,
                  itemBuilder: (ctx, idx) {
                    if (idx < startOffset) return const SizedBox();
                    final dayNum = idx - startOffset + 1;
                    final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                    final isToday = _isToday(date);
                    DiaryEntry? entry;
                    try {
                      entry = monthEntries.firstWhere(
                          (e) => e.createdAt.day == dayNum);
                    } catch (_) {}

                    return GestureDetector(
                      onTap: entry != null
                          ? () => Navigator.of(ctx).push(slideRightRoute(MoodDetailScreen(entry: entry!)))
                          : null,
                      child: _CalendarDay(
                          day: dayNum, entry: entry, isToday: isToday),
                    );
                  },
                ),
              ],
            ),
          ),

          // Mood legend
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(emoji: '😣', label: 'Awful'),
                _LegendItem(emoji: '😞', label: 'Bad'),
                _LegendItem(emoji: '😐', label: 'Okay'),
                _LegendItem(emoji: '😊', label: 'Good'),
                _LegendItem(emoji: '😄', label: 'Great'),
              ],
            ),
          ),

          // History list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('History Post and Notes',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E))),
                    Text('${monthEntries.length} entries',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF888780))),
                  ],
                ),
                const SizedBox(height: 14),
                if (monthEntries.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Text('📭', style: TextStyle(fontSize: 40)),
                          SizedBox(height: 8),
                          Text('No entries this month',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF888780))),
                        ],
                      ),
                    ),
                  )
                else
                  ...monthEntries.map((e) => GestureDetector(
                        onTap: () => Navigator.of(context).push(slideRightRoute(MoodDetailScreen(entry: e))),
                        child: _HistoryTile(entry: e),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _CalendarDay extends StatelessWidget {
  final int day;
  final DiaryEntry? entry;
  final bool isToday;
  const _CalendarDay({required this.day, required this.entry, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: entry != null
            ? entry!.moodColor.withOpacity(0.15)
            : isToday
                ? const Color(0xFFE1F5EE)
                : Colors.transparent,
        border: isToday
            ? Border.all(color: const Color(0xFF1D9E75), width: 1.5)
            : null,
      ),
      child: Center(
        child: entry != null
            ? Text(entry!.moodEmoji, style: const TextStyle(fontSize: 16))
            : Text(day.toString(),
                style: TextStyle(
                    fontSize: 11,
                    color: isToday
                        ? const Color(0xFF1D9E75)
                        : const Color(0xFF1A1A2E),
                    fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String emoji;
  final String label;
  const _LegendItem({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: Color(0xFF888780))),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final DiaryEntry entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: entry.moodColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
                child: Text(entry.moodEmoji,
                    style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: entry.moodColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(entry.moodLabel,
                          style: TextStyle(
                              fontSize: 10,
                              color: entry.moodColor,
                              fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    Text(
                      '${months[entry.createdAt.month - 1]} ${entry.createdAt.day}',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFFB4B2A9)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(entry.entryText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF444441),
                        height: 1.5)),
                if (entry.aiReflection != null) ...[
                  const SizedBox(height: 4),
                  Text('AI: ${entry.aiReflection}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1D9E75),
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              size: 16, color: Color(0xFFB4B2A9)),
        ],
      ),
    );
  }
}
