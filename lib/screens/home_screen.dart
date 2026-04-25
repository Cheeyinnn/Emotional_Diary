import 'dart:ui';

import 'package:emotion_diary/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../providers/diary_provider.dart';
import '../models/diary_entry.dart';
import '../utils/transitions.dart';
import 'log_mood_screen.dart';
import 'insight_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import '../activity/breathing_screen.dart';
import 'mood_detail_screen.dart';
import 'search_screen.dart';
import '../utils/activityRouter.dart';
import 'wellness_screen.dart';
import 'activityHistory_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;
  const HomeScreen({super.key, this.initialTab = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  int _homeRefreshKey = 0;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final isGuest = user == null;
        final authKey = user?.uid ?? 'guest';

        final screens = [
          _HomeTab(
            key: ValueKey('home_$authKey$_homeRefreshKey'),
            refreshKey: _homeRefreshKey,
            onNavigateToCalendar: () {
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
          CalendarScreen(key: ValueKey('calendar_$authKey')),
          _InsightWrapper(
            key: ValueKey('insight_$authKey'),
            isGuest: isGuest,
          ),
          ProfileScreen(key: ValueKey('profile_$authKey')),
        ];

        return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;

    // 👉 If NOT on Home → go Home first
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
        _homeRefreshKey++;
      });

      // reset back timer
      _lastBackPress = null;
      return;
    }

    final now = DateTime.now();

    // 👉 FIRST time on Home → exit directly
    if (_lastBackPress == null) {
      _lastBackPress = now;

      SystemNavigator.pop(); // 🔥 direct exit (no message)
      return;
    }

    // 👉 If user came back to Home from other tab
    if (now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    // 👉 Second press within 2s → exit
    SystemNavigator.pop();
  },
          child: Scaffold(
            body: IndexedStack(index: _selectedIndex, children: screens),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (i) {
                  setState(() {
                    _selectedIndex = i;

                    if (i == 0) {
                      _homeRefreshKey++;
                    }
                  });
                },
                backgroundColor: Colors.white,
                selectedItemColor: const Color(0xFF1D9E75),
                unselectedItemColor: const Color(0xFFB4B2A9),
                selectedLabelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month_outlined),
                    activeIcon: Icon(Icons.calendar_month),
                    label: 'Calendar',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.insights_outlined),
                    activeIcon: Icon(Icons.insights),
                    label: 'Insights',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InsightWrapper extends StatelessWidget {
  final bool isGuest;

  const _InsightWrapper({
    super.key,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const InsightScreen(),
        if (isGuest)
          Positioned.fill(
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      color: Colors.black.withOpacity(0.35),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 42),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE1F5EE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF1D9E75),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Unlock Insights',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Register an account to view your emotional insights, mood trends, and AI summary.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: Color(0xFF888780),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                fadeRoute(const RegisterScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D9E75),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Register Now',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Guest users can still log moods and view calendar history.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFFB4B2A9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HomeTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onNavigateToCalendar;

  const _HomeTab({super.key, required this.refreshKey, required this.onNavigateToCalendar,});
  

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _riskAlertsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadRiskAlertSetting();
  }

  @override
  void didUpdateWidget(covariant _HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshKey != widget.refreshKey) {
      _loadRiskAlertSetting();
    }
  }

  Future<void> _loadRiskAlertSetting() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _riskAlertsEnabled = prefs.getBool('risk_alerts') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    final last7 = provider.last7Days;
    final hasRisk = provider.has3DaySadStreak && _riskAlertsEnabled;
    final isAnalyzing = provider.isAnalyzing;

    final suggestions = last7
        .where((e) => e.activitySuggestion != null)
        .map((e) => e.activitySuggestion!)
        .toSet()
        .take(2)
        .toList();

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
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: _getUserDoc(),
                      builder: (context, snapshot) {
                        final userName = _extractUserName(snapshot);
                        final userInitial = userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : 'G';

                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFFE1F5EE),
                              child: Text(
                                userInitial,
                                style: const TextStyle(
                                  color: Color(0xFF0F6E56),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                Text(
                                  _greeting(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888780),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF1A1A2E)),
                      onPressed: () => Navigator.of(context).push(
                        fadeRoute(const SearchScreen()),
                      ),
                    ),
                    if (isAnalyzing)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5EE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Color(0xFF1D9E75),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'AI analyzing',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF0F6E56),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFF1A1A2E),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            if (hasRisk)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      slideUpRoute(const BreathingScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAECE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF5C4B3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.favorite_border,
                            color: Color(0xFF993C1D),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Your mood has been low recently. Tap to try a breathing exercise 🧘",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF993C1D),
                                height: 1.4,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Color(0xFF993C1D),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (provider.todayEntry != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      slideRightRoute(
                        MoodDetailScreen(entry: provider.todayEntry!),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F5EE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF9FE1CB)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            provider.todayEntry!.moodEmoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Today's mood logged ✓",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF085041),
                                  ),
                                ),
                                Text(
                                  'Feeling ${provider.todayEntry!.moodLabel} · Tap to view',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF0F6E56),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF1D9E75),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
                            Text(
                              'Balance Your\nMind and Life',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'How are you feeling today?',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
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
                        child: const Icon(
                          Icons.spa,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mood History',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          'This Week',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF1D9E75).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _MoodWeekRow(entries: last7),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _ActionCard(
                          icon: Icons.spa,
                          label: 'Wellness',
                          color: const Color(0xFFE1F5EE),
                          iconColor: const Color(0xFF1D9E75),
                          onTap: () => Navigator.of(context).push(
                            slideRightRoute(const WellnessScreen()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ActionCard(
                          icon: Icons.book_outlined,
                          label: 'Journal',
                          color: const Color(0xFFFAEEDA),
                          iconColor: const Color(0xFFBA7517),
                          onTap: () => Navigator.of(context).push(
                            slideUpRoute(const LogMoodScreen()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ActionCard(
                          icon: Icons.history,
                          label: 'History',
                          color: const Color(0xFFEEEDFE),
                          iconColor: const Color(0xFF534AB7),
                          onTap: () => Navigator.of(context).push(
                            slideRightRoute(const ActivityHistoryScreen()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'AI Activity Suggestions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F5EE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SMART',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF0F6E56),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (suggestions.isEmpty)
                      _SuggestionCard(
                        icon: Icons.air,
                        title: 'Box Breathing',
                        subtitle: 'Reduce stress instantly',
                        duration: '5 MIN',
                        color: const Color(0xFFE1F5EE),
                        onTap: () => Navigator.of(context).push(
                          slideUpRoute(const BreathingScreen()),
                        ),
                      )
                    else
                      ...suggestions.map(
                        (activity) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SuggestionCard(
                            icon: _activityIcon(activity),
                            title: activity,
                            subtitle: _activitySubtitle(activity),
                            duration: _activityDuration(activity),
                            color: const Color(0xFFE1F5EE),
                            onTap: () =>
                                ActivityRouter.navigate(context, activity),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (last7.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Entries',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onNavigateToCalendar, // 4. Use the callback here
                        child: const Text(
                         'See all',
                         style: TextStyle(
                         fontSize: 12,
                         color: Color(0xFF1D9E75),
                         ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final e = last7[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).push(
                          slideRightRoute(MoodDetailScreen(entry: e)),
                        ),
                        child: _RecentTile(entry: e),
                      ),
                    );
                  },
                  childCount: last7.take(3).length,
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
  final provider = context.read<DiaryProvider>();
  final todayEntry = provider.todayEntry;

  if (todayEntry != null) {
    Navigator.of(context).push(
      slideRightRoute(MoodDetailScreen(entry: todayEntry)),
    );
  } else {
    Navigator.of(context).push(
      slideUpRoute(const LogMoodScreen()),
    );
  }
},
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Log Mood',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDoc() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return FirebaseFirestore.instance.collection('users').doc('__guest__').get();
    }
    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  String _extractUserName(
    AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot,
  ) {
    if (snapshot.hasData && snapshot.data!.exists) {
      final data = snapshot.data!.data();
      final firestoreName = data?['name']?.toString().trim();
      if (firestoreName != null && firestoreName.isNotEmpty) {
        return firestoreName;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    final authName = user?.displayName?.trim();
    if (authName != null && authName.isNotEmpty) {
      return authName;
    }

    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Guest';
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤';
    return 'Good evening 🌙';
  }
}

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

String _activitySubtitle(String name) {
  final n = name.toLowerCase();
  if (n.contains('breath')) return 'Reduce stress instantly';
  if (n.contains('walk')) return 'Reconnect with surroundings';
  if (n.contains('meditat')) return 'Calm your mind';
  if (n.contains('gratitude') || n.contains('journal')) {
    return 'Shift your perspective';
  }
  if (n.contains('creative')) return 'Express your feelings';
  if (n.contains('sleep')) return 'Wind down for better rest';
  if (n.contains('stretch')) return 'Release tension in your body';
  return 'Take a mindful moment';
}

String _activityDuration(String name) {
  final n = name.toLowerCase();
  if (n.contains('breath')) return '5 MIN';
  if (n.contains('walk')) return '15 MIN';
  if (n.contains('meditat')) return '10 MIN';
  if (n.contains('sleep')) return '8 MIN';
  if (n.contains('stretch')) return '7 MIN';
  return '10 MIN';
}

class _MoodWeekRow extends StatelessWidget {
  final List<DiaryEntry> entries;
  const _MoodWeekRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final now = DateTime.now();

    // Sunday-based week start
    // DateTime.weekday: Mon = 1, Tue = 2, ..., Sun = 7
    // weekday % 7 makes Sun = 0, Mon = 1, Tue = 2 ...
    final startOffset = now.weekday % 7;
    final weekStart = now.subtract(Duration(days: startOffset));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));

        DiaryEntry? entry;
        try {
          entry = entries.firstWhere(
            (e) =>
                e.createdAt.year == day.year &&
                e.createdAt.month == day.month &&
                e.createdAt.day == day.day,
          );
        } catch (_) {}

        final isToday =
            day.day == now.day &&
            day.month == now.month &&
            day.year == now.year;

        return GestureDetector(
          onTap: entry != null
              ? () => Navigator.of(context).push(
                    slideRightRoute(MoodDetailScreen(entry: entry!)),
                  )
              : null,
          child: Column(
            children: [
              Text(
                days[i],
                style: TextStyle(
                  fontSize: 10,
                  color: isToday
                      ? const Color(0xFF1D9E75)
                      : const Color(0xFF888780),
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry != null
                      ? entry.moodColor.withOpacity(0.15)
                      : isToday
                          ? const Color(0xFFE1F5EE)
                          : const Color(0xFFF0F0F0),
                  border: isToday
                      ? Border.all(
                          color: const Color(0xFF1D9E75),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Center(
                  child: entry != null
                      ? Text(
                          entry.moodEmoji,
                          style: const TextStyle(fontSize: 18),
                        )
                      : Text(
                          day.day.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: isToday
                                ? const Color(0xFF1D9E75)
                                : const Color(0xFFB4B2A9),
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                ),
              ),
            ],
          ),
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: iconColor,
                ),
              ),
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
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888780),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                duration,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888780),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final DiaryEntry entry;
  const _RecentTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              child: Text(
                entry.moodEmoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
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
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _timeAgo(entry.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFB4B2A9),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 16,
            color: Color(0xFFB4B2A9),
          ),
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