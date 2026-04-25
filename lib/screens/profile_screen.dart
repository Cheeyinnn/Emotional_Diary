import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/diary_provider.dart';
import '../services/pdf_export_service.dart';
import '../services/notification_service.dart';
import '../utils/transitions.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _name = 'Guest';
  String _email = 'guest@emotiondiary.app';

  bool _dailyReminder = true;
  bool _riskAlerts = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);

  bool _isLoadingProfile = true;
  bool _isSavingProfile = false;

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _name = 'Guest';
        _email = 'guest@emotiondiary.app';
        _nameCtrl.text = _name;
        _emailCtrl.text = _email;
        _isLoadingProfile = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      final firestoreName = data?['name']?.toString().trim();
      final authName = user.displayName?.trim();
      final authEmail = user.email?.trim();

      setState(() {
        _name = firestoreName?.isNotEmpty == true
            ? firestoreName!
            : authName?.isNotEmpty == true
                ? authName!
                : authEmail?.split('@').first ?? 'User';

        _email = authEmail?.isNotEmpty == true
            ? authEmail!
            : data?['email']?.toString() ?? 'No email';

        _nameCtrl.text = _name;
        _emailCtrl.text = _email;
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() => _isLoadingProfile = false);
      _showSnackBar('Failed to load profile: $e', isError: true);
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final dailyReminder = prefs.getBool('daily_reminder') ?? true;
    final riskAlerts = prefs.getBool('risk_alerts') ?? true;
    final hour = prefs.getInt('reminder_hour') ?? 21;
    final minute = prefs.getInt('reminder_minute') ?? 0;

    setState(() {
      _dailyReminder = dailyReminder;
      _riskAlerts = riskAlerts;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });

    if (_dailyReminder) {
      await NotificationService.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    } else {
      await NotificationService.cancelDailyReminder();
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('daily_reminder', _dailyReminder);
    await prefs.setBool('risk_alerts', _riskAlerts);
    await prefs.setInt('reminder_hour', _reminderTime.hour);
    await prefs.setInt('reminder_minute', _reminderTime.minute);

    if (_dailyReminder) {
      await NotificationService.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    } else {
      await NotificationService.cancelDailyReminder();
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar('Please sign in to edit your profile.', isError: true);
      return;
    }

    final newName = _nameCtrl.text.trim();
    final newEmail = _emailCtrl.text.trim();

    if (newName.isEmpty || newEmail.isEmpty) {
      _showSnackBar('Name and email cannot be empty.', isError: true);
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': newName,
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.updateDisplayName(newName);

      if (newEmail != user.email) {
        await user.verifyBeforeUpdateEmail(newEmail);
      }

      setState(() {
        _name = newName;
        _email = newEmail;
      });

      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Profile updated successfully.');
    } on FirebaseAuthException catch (e) {
      _showSnackBar(
        e.code == 'requires-recent-login'
            ? 'Please sign in again before changing email.'
            : 'Failed to update profile: ${e.message}',
        isError: true,
      );
    } catch (e) {
      _showSnackBar('Failed to update profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
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

    if (picked == null) return;

    setState(() => _reminderTime = picked);

    await _saveSettings();

    _showSnackBar(
      _dailyReminder
          ? 'Reminder updated to ${_formatTime(_reminderTime)}.'
          : 'Reminder time saved. Turn on Daily Reminder to activate it.',
    );
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your diary entries and AI insights. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFE24B4A)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context.read<DiaryProvider>().clearAllEntries();

      if (!mounted) return;

      _showSnackBar('All diary data has been cleared.', isError: true);
    } catch (e) {
      _showSnackBar('Failed to clear data: $e', isError: true);
    }
  }

  Future<void> _exportPdf() async {
    if (_isGuest) {
      _showSnackBar(
        'Please sign in to export PDF report.',
        isError: true,
      );
      return;
    }

    final provider = context.read<DiaryProvider>();

    if (provider.entries.isEmpty) {
      _showSnackBar('No entries to export yet.');
      return;
    }

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
      final user = FirebaseAuth.instance.currentUser;

      final path = await PdfExportService.exportDiary(
        provider.entries,
        userName: user?.displayName,
        userEmail: user?.email,
      );

      if (!mounted) return;
      Navigator.pop(context);

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'My Emotion Diary Export',
        text: 'Here is my emotion diary export from the AI Emotion Diary app.',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Export failed: $e', isError: true);
    }
  }

  Future<void> _goToWelcome() async {
    Navigator.of(context).pushAndRemoveUntil(
      fadeScaleRoute(const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _signOutOrSignIn() async {
    if (_isGuest) {
      await _goToWelcome();
      return;
    }

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    await _goToWelcome();
  }

  void _showEditProfileDialog() {
    if (_isGuest) {
      _showSnackBar('Please sign in to edit your profile.', isError: true);
      return;
    }

    _nameCtrl.text = _name;
    _emailCtrl.text = _email;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSavingProfile ? null : () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSavingProfile ? null : _saveProfile,
            child: _isSavingProfile
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text(
          'Your diary entries are private and used only to provide mood tracking, AI reflection, and emotional insight features. Do not use this app as a replacement for professional mental health support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor:
            isError ? const Color(0xFFE24B4A) : const Color(0xFF1D9E75),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = _isGuest;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1D9E75)),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _profileHeader(),
                const SizedBox(height: 20),

                _sectionTitle('Account'),
                _card(
                  child: Column(
                    children: [
                      _TapTile(
                        icon: Icons.edit_outlined,
                        label: 'Edit Profile',
                        onTap: _showEditProfileDialog,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _sectionTitle('Preferences'),
                _card(
                  child: Column(
                    children: [
                      _SwitchTile(
                        icon: Icons.notifications_outlined,
                        label: 'Daily Reminder',
                        value: _dailyReminder,
                        onChanged: (v) async {
  setState(() => _dailyReminder = v);

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('daily_reminder', v);

  if (v) {
    await NotificationService.scheduleDailyReminder(
      hour: _reminderTime.hour,
      minute: _reminderTime.minute,
    );

    _showSnackBar(
      'Daily reminder set at ${_formatTime(_reminderTime)}.',
    );
  } else {
    await NotificationService.cancelDailyReminder();

    _showSnackBar('Daily reminder turned off.');
  }
},
                      ),
                      _divider(),
                      _TapTile(
                        icon: Icons.schedule_outlined,
                        label: 'Reminder Time: ${_formatTime(_reminderTime)}',
                        onTap: _pickTime,
                      ),
                      _divider(),
                      _SwitchTile(
                        icon: Icons.favorite_border,
                        label: 'Risk Alerts',
                        value: _riskAlerts,
                        onChanged: (v) async {
                          setState(() => _riskAlerts = v);
                          await _saveSettings();

                          _showSnackBar(
                            v
                                ? 'Risk alerts turned on.'
                                : 'Risk alerts turned off.',
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _sectionTitle('Data'),
                _card(
                  child: Column(
                    children: [
                      _TapTile(
                        icon: Icons.picture_as_pdf_outlined,
                        label: isGuest
                            ? 'Export PDF Report (Sign in required)'
                            : 'Export Diary as PDF',
                        textColor: isGuest ? const Color(0xFFB4B2A9) : null,
                        onTap: _exportPdf,
                      ),
                      _divider(),
                      _TapTile(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        onTap: _showPrivacyDialog,
                      ),
                      _divider(),
                      _TapTile(
                        icon: Icons.delete_outline,
                        label: 'Clear All Data',
                        textColor: const Color(0xFFE24B4A),
                        onTap: _clearAllData,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _card(
                  child: _TapTile(
                    icon: isGuest ? Icons.login : Icons.logout,
                    label: isGuest ? 'Sign In' : 'Sign Out',
                    textColor: isGuest
                        ? const Color(0xFF1D9E75)
                        : const Color(0xFFE24B4A),
                    onTap: _signOutOrSignIn,
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _profileHeader() {
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'G';
    final isGuest = _isGuest;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D9E75), Color(0xFF0F6E56)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F6E56),
                  ),
                ),
              ),
              if (!isGuest)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAEEDA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 13,
                      color: Color(0xFFBA7517),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isGuest ? 'Guest Mode' : 'Emotion Diary User',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF888780),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: child,
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      thickness: 0.5,
      color: Color(0xFFE0E0E0),
      indent: 16,
      endIndent: 16,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: const Color(0xFF888780),
        size: 20,
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF1A1A2E),
        ),
      ),
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
      leading: Icon(
        icon,
        color: textColor ?? const Color(0xFF888780),
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: textColor ?? const Color(0xFF1A1A2E),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFFB4B2A9),
        size: 18,
      ),
      onTap: onTap,
      dense: true,
    );
  }
}