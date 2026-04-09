import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../models/diary_entry.dart';
import 'log_mood_screen.dart';
import 'insight_screen.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    CalendarScreen(),
    InsightScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1D9E75),
          unselectedItemColor: const Color(0xFFB4B2A9),
          selectedLabelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: Icon(Icons.calendar_month),
                label: 'Calendar'),
            BottomNavigationBarItem(
                icon: Icon(Icons.insights_outlined),
                activeIcon: Icon(Icons.insights),
                label: 'Insights'),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    final last7 = provider.last7Days;
    final hasRisk = provider.hasRiskFlag;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFE1F5EE),
                      child: Text('A',
                          style: TextStyle(
                              color: Color(0xFF0F6E56),
                              fontWeight: FontWeight.w600,
                              fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Au Xiao Xuan',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF1A1A2E))),
                        Text(_greeting(),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF888780))),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Color(0xFF1A1A2E)),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // Risk flag banner
            if (hasRisk)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAECE7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF5C4B3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.favorite_border,
                            color: Color(0xFF993C1D), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "We noticed your mood has been low recently. Would you like to try a breathing exercise?",
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF993C1D),
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Hero card - Balance your mind
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D9E75), Color(0xFF0F6E56)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Balance Your\nMind and Life',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.3)),
                            SizedBox(height: 8),
                            Text('How are you feeling today?',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.spa, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Mood History (last 7 days)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mood History',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E))),
                        Text('This Week',
                            style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF1D9E75).withOpacity(0.8))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _MoodWeekRow(entries: last7),
                  ],
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Actions',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _ActionCard(
                          icon: Icons.self_improvement,
                          label: 'Meditate',
                          color: const Color(0xFFE1F5EE),
                          iconColor: const Color(0xFF1D9E75),
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _ActionCard(
                          icon: Icons.book_outlined,
                          label: 'Journal',
                          color: const Color(0xFFFAEEDA),
                          iconColor: const Color(0xFFBA7517),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const LogMoodScreen()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ActionCard(
                          icon: Icons.chat_bubble_outline,
                          label: 'Talk',
                          color: const Color(0xFFEEEDFE),
                          iconColor: const Color(0xFF534AB7),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // AI Activity Suggestions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('AI Activity Suggestions',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F5EE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('SMART',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF0F6E56),
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SuggestionCard(
                      icon: Icons.air,
                      title: 'Deep Breathing',
                      subtitle: 'Reduce stress instantly',
                      duration: '3 MIN',
                      color: const Color(0xFFE1F5EE),
                    ),
                    const SizedBox(height: 10),
                    _SuggestionCard(
                      icon: Icons.directions_walk,
                      title: 'Mindful Walk',
                      subtitle: 'Reconnect with surroundings',
                      duration: '15 MIN',
                      color: const Color(0xFFEAF3DE),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LogMoodScreen()),
        ),
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log Mood',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤';
    return 'Good evening 🌙';
  }
}

class _MoodWeekRow extends StatelessWidget {
  final List<DiaryEntry> entries;
  const _MoodWeekRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        DiaryEntry? entry;
        try {
          entry = entries.firstWhere((e) =>
              e.createdAt.year == day.year &&
              e.createdAt.month == day.month &&
              e.createdAt.day == day.day);
        } catch (_) {}

        final isToday = day.day == now.day &&
            day.month == now.month &&
            day.year == now.year;

        return Column(
          children: [
            Text(days[i],
                style: TextStyle(
                    fontSize: 10,
                    color: isToday
                        ? const Color(0xFF1D9E75)
                        : const Color(0xFF888780),
                    fontWeight:
                        isToday ? FontWeight.w600 : FontWeight.w400)),
            const SizedBox(height: 6),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: entry != null
                    ? entry.moodColor.withOpacity(0.15)
                    : const Color(0xFFF0F0F0),
                border: isToday
                    ? Border.all(
                        color: const Color(0xFF1D9E75), width: 1.5)
                    : null,
              ),
              child: Center(
                child: entry != null
                    ? Text(entry.moodEmoji, style: const TextStyle(fontSize: 18))
                    : Text(day.day.toString(),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFB4B2A9))),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: iconColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String duration;
  final Color color;

  const _SuggestionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF1D9E75), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF888780))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(duration,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888780))),
          ),
        ],
      ),
    );
  }
}
