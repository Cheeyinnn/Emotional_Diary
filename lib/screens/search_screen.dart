import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../models/diary_entry.dart';
import 'mood_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _moodFilters = [
    {'emoji': '😣', 'label': 'Awful', 'mood': 0, 'color': Color(0xFFE24B4A)},
    {'emoji': '😞', 'label': 'Bad', 'mood': 1, 'color': Color(0xFFEF9F27)},
    {'emoji': '😐', 'label': 'Okay', 'mood': 2, 'color': Color(0xFF888780)},
    {'emoji': '😊', 'label': 'Good', 'mood': 3, 'color': Color(0xFF1D9E75)},
    {'emoji': '😄', 'label': 'Great', 'mood': 4, 'color': Color(0xFF378ADD)},
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    // Restore existing search state
    final provider = context.read<DiaryProvider>();
    _searchCtrl.text = provider.searchQuery;
    _searchCtrl.addListener(() {
      context.read<DiaryProvider>().setSearch(_searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    final results = provider.filteredEntries;
    final activeFilter = provider.filterMood;
    final hasActiveFilters =
        provider.searchQuery.isNotEmpty || activeFilter != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: _SearchBar(controller: _searchCtrl),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () {
            provider.clearFilters();
            Navigator.pop(context);
          },
        ),
        leadingWidth: 40,
        actions: [
          if (hasActiveFilters)
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                provider.clearFilters();
              },
              child: const Text('Clear',
                  style: TextStyle(
                      color: Color(0xFFE24B4A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood filter chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter by mood',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888780),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // "All" chip
                        _FilterChip(
                          emoji: '✨',
                          label: 'All',
                          selected: activeFilter == null,
                          color: const Color(0xFF1D9E75),
                          onTap: () => provider.setFilterMood(null),
                        ),
                        const SizedBox(width: 8),
                        ..._moodFilters.map((m) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterChip(
                                emoji: m['emoji'] as String,
                                label: m['label'] as String,
                                selected: activeFilter == m['mood'],
                                color: m['color'] as Color,
                                onTap: () =>
                                    provider.setFilterMood(m['mood'] as int),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Results count
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Text(
                    '${results.length} result${results.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E)),
                  ),
                  if (hasActiveFilters) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F5EE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Filtered',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF0F6E56),
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),

            // Results list
            Expanded(
              child: results.isEmpty
                  ? _EmptyState(
                      hasQuery: provider.searchQuery.isNotEmpty ||
                          activeFilter != null)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: results.length,
                      itemBuilder: (ctx, i) {
                        final entry = results[i];
                        return _SearchResultTile(
                          entry: entry,
                          query: provider.searchQuery,
                          onTap: () => Navigator.of(ctx).push(
                            _slideRoute(MoodDetailScreen(entry: entry)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
        decoration: const InputDecoration(
          hintText: 'Search entries, triggers, reflections...',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFFB4B2A9)),
          prefixIcon:
              Icon(Icons.search, size: 18, color: Color(0xFF888780)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: selected ? color : const Color(0xFF888780),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

// ── Search Result Tile ───────────────────────────────────────────────────────

class _SearchResultTile extends StatelessWidget {
  final DiaryEntry entry;
  final String query;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.entry,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final dateStr =
        '${months[entry.createdAt.month - 1]} ${entry.createdAt.day}, ${entry.createdAt.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              width: 42,
              height: 42,
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
                      Text(dateStr,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFFB4B2A9))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Highlighted text
                  _HighlightedText(
                      text: entry.entryText, query: query, maxLines: 2),
                  if (entry.triggerKeyword != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.bolt,
                            size: 12, color: Color(0xFFBA7517)),
                        const SizedBox(width: 2),
                        _HighlightedText(
                          text: entry.triggerKeyword!,
                          query: query,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF888780)),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: Color(0xFFB4B2A9)),
          ],
        ),
      ),
    );
  }
}

// ── Highlighted Text ─────────────────────────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final int maxLines;

  const _HighlightedText({
    required this.text,
    required this.query,
    this.style,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: style ??
              const TextStyle(
                  fontSize: 13, color: Color(0xFF1A1A2E), height: 1.4));
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: const TextStyle(
          backgroundColor: Color(0xFFFAF08A),
          color: Color(0xFF1A1A2E),
          fontWeight: FontWeight.w600,
        ),
      ));
      start = idx + query.length;
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: style ??
            const TextStyle(
                fontSize: 13, color: Color(0xFF1A1A2E), height: 1.4),
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(hasQuery ? '🔍' : '📔',
              style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            hasQuery ? 'No entries found' : 'Start searching',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuery
                ? 'Try different keywords\nor clear the filter'
                : 'Search by text, mood, or trigger',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF888780)),
          ),
        ],
      ),
    );
  }
}

// ── Route helpers ─────────────────────────────────────────────────────────────

PageRouteBuilder _slideRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 280),
    );
