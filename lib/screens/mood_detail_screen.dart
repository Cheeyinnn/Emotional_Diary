import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import 'log_mood_screen.dart';

class MoodDetailScreen extends StatefulWidget {
  final DiaryEntry entry;
  const MoodDetailScreen({super.key, required this.entry});

  @override
  State<MoodDetailScreen> createState() => _MoodDetailScreenState();
}

class _MoodDetailScreenState extends State<MoodDetailScreen>
    with SingleTickerProviderStateMixin {
  late DiaryEntry _entry;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn);
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<DiaryEntry>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            LogMoodScreen(existingEntry: _entry),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
    if (updated != null) {
      setState(() => _entry = updated);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry?'),
        content:
            const Text('This diary entry will be permanently deleted.'),
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
      context.read<DiaryProvider>().deleteEntry(_entry.id);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    final dateStr =
        '${months[_entry.createdAt.month - 1]} ${_entry.createdAt.day}, ${_entry.createdAt.year}';
    final timeStr =
        '${_entry.createdAt.hour.toString().padLeft(2, '0')}:${_entry.createdAt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(dateStr,
            style: const TextStyle(fontSize: 15)),
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _openEdit,
            tooltip: 'Edit',
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFFE24B4A)),
            onPressed: _confirmDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Mood hero card
              _heroCard(timeStr),
              const SizedBox(height: 16),

              // Diary text
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit_note,
                            size: 18, color: Color(0xFF1D9E75)),
                        SizedBox(width: 8),
                        Text('My Entry',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _entry.entryText,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF444441),
                          height: 1.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // AI Reflection
              if (_entry.aiReflection != null)
                _card(
                  accent: const Color(0xFFE1F5EE),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 18, color: Color(0xFF1D9E75)),
                          SizedBox(width: 8),
                          Text('AI Reflection',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF085041))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _entry.aiReflection!,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0F6E56),
                            height: 1.7,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                )
              else
                _card(
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xFF1D9E75)),
                      ),
                      SizedBox(width: 10),
                      Text('AI analysis in progress...',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFFB4B2A9))),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Edit button at bottom
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _openEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D9E75),
                    side: const BorderSide(color: Color(0xFF1D9E75)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit This Entry',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCard(String timeStr) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _entry.moodColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _entry.moodColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'mood_emoji_${_entry.id}',
            child: Text(_entry.moodEmoji,
                style: const TextStyle(fontSize: 56)),
          ),
          const SizedBox(height: 8),
          Text(_entry.moodLabel,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _entry.moodColor)),
          const SizedBox(height: 4),
          Text(timeStr,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF888780))),
          if (_entry.emotionIntensity != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Emotion Intensity',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF888780))),
                const Spacer(),
                Text(
                  '${_entry.emotionIntensity!.toStringAsFixed(1)} / 10',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _entry.moodColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _entry.emotionIntensity! / 10.0,
                backgroundColor: _entry.moodColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(_entry.moodColor),
                minHeight: 6,
              ),
            ),
          ],
          if (_entry.triggerKeyword != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt,
                      size: 14, color: Color(0xFFBA7517)),
                  const SizedBox(width: 4),
                  Text('# ${_entry.triggerKeyword}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF633806),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child, Color? accent}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: child,
      );
}
