import 'package:flutter/material.dart';
import '../utils/transitions.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/diary_provider.dart';
import '../services/pdf_export_service.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Au Xiao Xuan';
  String _email = 'auxiaoxuan@gmail.com';
  bool _dailyReminder = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);
  bool _riskAlerts = true;
  bool _weeklyReport = true;
  String _selectedGoal = 'Reduce stress';

  final _goals = [
    'Reduce stress',
    'Better sleep',
    'Improve mood',
    'Build self-awareness',
    'Track anxiety',
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name') ?? 'Au Xiao Xuan';
      _email = prefs.getString('user_email') ?? 'auxiaoxuan@gmail.com';
      _dailyReminder = prefs.getBool('daily_reminder') ?? true;
      _riskAlerts = prefs.getBool('risk_alerts') ?? true;
      _weeklyReport = prefs.getBool('weekly_report') ?? true;
      _selectedGoal = prefs.getString('goal') ?? 'Reduce stress';
      final h = prefs.getInt('reminder_hour') ?? 21;
      final m = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: h, minute: m);
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _name);
    await prefs.setString('user_email', _email);
    await prefs.setBool('daily_reminder', _dailyReminder);
    await prefs.setBool('risk_alerts', _riskAlerts);
    await prefs.setBool('weekly_report', _weeklyReport);
    await prefs.setString('goal', _selectedGoal);
    await prefs.setInt('reminder_hour', _reminderTime.hour);
    await prefs.setInt('reminder_minute', _reminderTime.minute);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved!'),
          backgroundColor: Color(0xFF1D9E75),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1D9E75),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
            'This will permanently delete all your diary entries and AI insights. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFE24B4A))),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('diary_entries');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared.'),
          backgroundColor: Color(0xFFE24B4A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportPdf() async {
    final provider = context.read<DiaryProvider>();
    if (provider.entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No entries to export yet!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFF1D9E75)),
            SizedBox(width: 16),
            Text('Generating PDF...'),
          ],
        ),
      ),
    );

    try {
      final path = await PdfExportService.exportDiary(provider.entries);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'My Emotion Diary Export',
        text: 'Here is my emotion diary export from the AI Emotion Diary app.',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: const Color(0xFFE24B4A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _signOut() {
    Navigator.of(context).pushAndRemoveUntil(
      fadeScaleRoute(const WelcomeScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    final totalEntries = provider.entries.length;
    final avgMood = totalEntries == 0
        ? 0.0
        : provider.entries.map((e) => e.mood).reduce((a, b) => a + b) /
            totalEntries;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          TextButton(
            onPressed: _savePrefs,
            child: const Text('Save',
                style: TextStyle(
                    color: Color(0xFF1D9E75), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar + stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D9E75), Color(0xFF0F6E56)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        _name.isNotEmpty ? _name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            size: 14, color: Color(0xFF1D9E75)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_name,
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
                Text(_email,
                    style: TextStyle(
                        fontSize: 12, color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                        value: totalEntries.toString(), label: 'Entries'),
                    Container(width: 1, height: 32, color: Colors.white24),
                    _StatItem(
                        value: avgMood.toStringAsFixed(1), label: 'Avg Mood'),
                    Container(width: 1, height: 32, color: Colors.white24),
                    _StatItem(
                        value: provider.last7Days.length.toString(),
                        label: 'This Week'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Personal info
          _SectionHeader(title: 'Personal Info'),
          _SettingsCard(
            children: [
              _EditableTile(
                icon: Icons.person_outline,
                label: 'Name',
                value: _name,
                onChanged: (v) => setState(() => _name = v),
              ),
              const Divider(height: 1, indent: 52),
              _EditableTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: _email,
                onChanged: (v) => setState(() => _email = v),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Goal
          _SectionHeader(title: 'My Wellness Goal'),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _goals
                      .map(
                        (g) => GestureDetector(
                          onTap: () => setState(() => _selectedGoal = g),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedGoal == g
                                  ? const Color(0xFF1D9E75)
                                  : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(g,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _selectedGoal == g
                                        ? Colors.white
                                        : const Color(0xFF888780),
                                    fontWeight: _selectedGoal == g
                                        ? FontWeight.w600
                                        : FontWeight.w400)),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notifications
          _SectionHeader(title: 'Notifications'),
          _SettingsCard(
            children: [
              _SwitchTile(
                icon: Icons.notifications_outlined,
                label: 'Daily Reminder',
                subtitle: 'Reminds you to log your mood',
                value: _dailyReminder,
                onChanged: (v) => setState(() => _dailyReminder = v),
              ),
              if (_dailyReminder) ...[
                const Divider(height: 1, indent: 52),
                ListTile(
                  leading: const Icon(Icons.access_time,
                      color: Color(0xFF888780), size: 20),
                  title: const Text('Reminder Time',
                      style: TextStyle(fontSize: 13)),
                  trailing: TextButton(
                    onPressed: _pickTime,
                    child: Text(
                      _reminderTime.format(context),
                      style: const TextStyle(
                          color: Color(0xFF1D9E75),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
              const Divider(height: 1, indent: 52),
              _SwitchTile(
                icon: Icons.warning_amber_outlined,
                label: 'Risk Alerts',
                subtitle: 'Alert when mood is low for 3+ days',
                value: _riskAlerts,
                onChanged: (v) => setState(() => _riskAlerts = v),
              ),
              const Divider(height: 1, indent: 52),
              _SwitchTile(
                icon: Icons.summarize_outlined,
                label: 'Weekly AI Report',
                subtitle: 'Get your summary every Monday',
                value: _weeklyReport,
                onChanged: (v) => setState(() => _weeklyReport = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Data & Privacy
          _SectionHeader(title: 'Data & Privacy'),
          _SettingsCard(
            children: [
              _TapTile(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Export Diary as PDF',
                textColor: const Color(0xFF1D9E75),
                onTap: _exportPdf,
              ),
              const Divider(height: 1, indent: 52),
              _TapTile(
                icon: Icons.lock_outline,
                label: 'Privacy Policy',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 52),
              _TapTile(
                icon: Icons.delete_outline,
                label: 'Clear All Data',
                textColor: const Color(0xFFE24B4A),
                onTap: _clearAllData,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sign out
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE24B4A),
                side: const BorderSide(color: Color(0xFFE24B4A)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),

          const Center(
            child: Text('Emotion Diary v1.0.0 — UCCD3223 Group 39',
                style: TextStyle(fontSize: 11, color: Color(0xFFB4B2A9))),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF888780),
              letterSpacing: 0.5)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _EditableTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  const _EditableTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF888780), size: 20),
      title: Text(label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF888780))),
      subtitle: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w500),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: const Color(0xFF888780), size: 20),
      title:
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E))),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 11, color: Color(0xFFB4B2A9))),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF1D9E75),
      dense: true,
    );
  }
}

class _TapTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;

  const _TapTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          Icon(icon, color: textColor ?? const Color(0xFF888780), size: 20),
      title: Text(label,
          style: TextStyle(
              fontSize: 13,
              color: textColor ?? const Color(0xFF1A1A2E))),
      trailing: const Icon(Icons.chevron_right,
          color: Color(0xFFB4B2A9), size: 18),
      onTap: onTap,
      dense: true,
    );
  }
}
