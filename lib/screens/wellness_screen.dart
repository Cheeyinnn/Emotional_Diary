import 'package:flutter/material.dart';
import '../utils/transitions.dart';
import '../utils/activityRouter.dart';

class WellnessScreen extends StatelessWidget {
  const WellnessScreen({super.key});

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
          'Wellness Activities',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D9E75), Color(0xFF0F6E56)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                        'Take a moment\nfor yourself 🌿',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Choose an activity that fits\nhow you feel right now.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
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
          const SizedBox(height: 28),

          // ── Calm Down ──────────────────────────────────────────────────────
          _sectionHeader(
            emoji: '🌬️',
            title: 'Calm Down',
            subtitle: 'For when you feel stressed or overwhelmed',
            color: const Color(0xFF1D9E75),
          ),
          const SizedBox(height: 12),
          _ActivityCard(
            icon: Icons.air,
            title: 'Box Breathing',
            subtitle: 'A structured breathing technique to instantly reduce anxiety.',
            duration: '5 MIN',
            bgColor: const Color(0xFFE1F5EE),
            iconColor: const Color(0xFF1D9E75),
            onTap: () => ActivityRouter.navigate(context, 'Box Breathing'),
          ),
          const SizedBox(height: 10),
          _ActivityCard(
            icon: Icons.self_improvement,
            title: 'Guided Meditation',
            subtitle: 'Quiet your thoughts and return to the present moment.',
            duration: '10 MIN',
            bgColor: const Color(0xFFEEEDFE),
            iconColor: const Color(0xFF534AB7),
            onTap: () => ActivityRouter.navigate(context, 'Guided Meditation'),
          ),
          const SizedBox(height: 10),
          _ActivityCard(
            icon: Icons.bedtime_outlined,
            title: 'Sleep Hygiene',
            subtitle: 'Wind down your body and mind for better rest tonight.',
            duration: '8 MIN',
            bgColor: const Color(0xFFDDEEFA),
            iconColor: const Color(0xFF378ADD),
            onTap: () => ActivityRouter.navigate(context, 'Sleep Hygiene'),
          ),
          const SizedBox(height: 28),

          // ── Move & Reset ───────────────────────────────────────────────────
          _sectionHeader(
            emoji: '🚶',
            title: 'Move & Reset',
            subtitle: 'For when you need to shake off tension',
            color: const Color(0xFFEF9F27),
          ),
          const SizedBox(height: 12),
          _ActivityCard(
            icon: Icons.directions_walk,
            title: 'Mindful Walk',
            subtitle: 'Step outside and reconnect with your surroundings.',
            duration: '15 MIN',
            bgColor: const Color(0xFFEAF3DE),
            iconColor: const Color(0xFF5A8A2F),
            onTap: () => ActivityRouter.navigate(context, 'Mindful Walk'),
          ),
          const SizedBox(height: 10),
          _ActivityCard(
            icon: Icons.accessibility_new,
            title: 'Body Stretching',
            subtitle: 'Release physical tension that mirrors your emotional stress.',
            duration: '7 MIN',
            bgColor: const Color(0xFFFAEEDA),
            iconColor: const Color(0xFFEF9F27),
            onTap: () => ActivityRouter.navigate(context, 'Body Stretching'),
          ),
          const SizedBox(height: 28),

          // ── Reflect ────────────────────────────────────────────────────────
          _sectionHeader(
            emoji: '✍️',
            title: 'Reflect',
            subtitle: 'For when you want to understand yourself better',
            color: const Color(0xFFBA7517),
          ),
          const SizedBox(height: 12),
          _ActivityCard(
            icon: Icons.edit_note,
            title: 'Gratitude Journaling',
            subtitle: 'Shift your focus to what\'s going well in your life.',
            duration: '10 MIN',
            bgColor: const Color(0xFFFAEEDA),
            iconColor: const Color(0xFFBA7517),
            onTap: () => ActivityRouter.navigate(context, 'Gratitude Journaling'),
          ),
          const SizedBox(height: 10),
          _ActivityCard(
            icon: Icons.brush_outlined,
            title: 'Creative Expression',
            subtitle: 'Express your feelings through art, writing, or music.',
            duration: '15 MIN',
            bgColor: const Color(0xFFFAECE7),
            iconColor: const Color(0xFFE24B4A),
            onTap: () => ActivityRouter.navigate(context, 'Creative Expression'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
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
      ],
    );
  }
}

// ─── Activity Card ────────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String duration;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888780),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    duration,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right,
                    size: 16, color: Color(0xFFB4B2A9)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}