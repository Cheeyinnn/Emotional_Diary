import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/diary_provider.dart';
import '../models/diary_entry.dart';
import 'ai_respond_screen.dart';
import 'mood_detail_screen.dart';

class LogMoodScreen extends StatefulWidget {
  final DiaryEntry? existingEntry;
  final DateTime? customDate;

  const LogMoodScreen({
    super.key,
    this.existingEntry,
    this.customDate,
  });

  bool get isEditing => existingEntry != null;

  @override
  State<LogMoodScreen> createState() => _LogMoodScreenState();
}

class _LogMoodScreenState extends State<LogMoodScreen>
    with SingleTickerProviderStateMixin {
  int _selectedMood = 2;
  final _textCtrl = TextEditingController();
  bool _isSaving = false;
  bool _alreadyCheckedToday = false;

  late AnimationController _emojiAnimCtrl;
  late Animation<double> _emojiScale;

  static const _moods = [
    {'emoji': '😣', 'label': 'Awful', 'color': Color(0xFFE24B4A)},
    {'emoji': '😞', 'label': 'Bad', 'color': Color(0xFFEF9F27)},
    {'emoji': '😐', 'label': 'Okay', 'color': Color(0xFF888780)},
    {'emoji': '😊', 'label': 'Good', 'color': Color(0xFF1D9E75)},
    {'emoji': '😄', 'label': 'Great', 'color': Color(0xFF378ADD)},
  ];

  @override
  void initState() {
    super.initState();

    if (widget.existingEntry != null) {
      _selectedMood = widget.existingEntry!.mood;
      _textCtrl.text = widget.existingEntry!.entryText == 'No note added.'
          ? ''
          : widget.existingEntry!.entryText;
    }

    _emojiAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _emojiScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _emojiAnimCtrl, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfAlreadyLogged();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _emojiAnimCtrl.dispose();
    super.dispose();
  }

  DateTime get _targetDate => widget.customDate ?? DateTime.now();

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DiaryEntry? _findExistingEntryForTargetDate(DiaryProvider provider) {
    try {
      return provider.entries.firstWhere(
        (e) => _sameDate(e.createdAt, _targetDate),
      );
    } catch (_) {
      return null;
    }
  }

  void _redirectIfAlreadyLogged() {
    if (!mounted) return;
    if (_alreadyCheckedToday) return;
    if (widget.isEditing) return;

    _alreadyCheckedToday = true;

    final provider = context.read<DiaryProvider>();
    final existingEntry = _findExistingEntryForTargetDate(provider);

    if (existingEntry != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MoodDetailScreen(entry: existingEntry),
        ),
      );
    }
  }

  void _selectMood(int i) {
    setState(() => _selectedMood = i);
    _emojiAnimCtrl.forward().then((_) => _emojiAnimCtrl.reverse());
  }

  DiaryEntry _getLatestEntryFromProvider(
    DiaryProvider provider,
    String entryId,
    DiaryEntry fallback,
  ) {
    try {
      return provider.entries.firstWhere((e) => e.id == entryId);
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final provider = context.read<DiaryProvider>();
    final text =
        _textCtrl.text.trim().isEmpty ? 'No note added.' : _textCtrl.text.trim();

    try {
      if (widget.isEditing) {
        final result = await provider.editEntry(
          id: widget.existingEntry!.id,
          entryText: text,
          mood: _selectedMood,
        );

        final baseEntry = result['entry'] as DiaryEntry;
        final updatedEntry =
            _getLatestEntryFromProvider(provider, baseEntry.id, baseEntry);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry updated!'),
            backgroundColor: Color(0xFF1D9E75),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pop(updatedEntry);
      } else {
        final existingEntry = _findExistingEntryForTargetDate(provider);

        if (existingEntry != null) {
          if (!mounted) return;

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MoodDetailScreen(entry: existingEntry),
            ),
          );
          return;
        }

        final data = await provider.addEntry(
          entryText: text,
          mood: _selectedMood,
          createdAt: widget.customDate,
        );

        final baseEntry = data['entry'] as DiaryEntry;
        final aiResult = data['aiResult'] as Map<String, dynamic>;
        final updatedEntry =
            _getLatestEntryFromProvider(provider, baseEntry.id, baseEntry);

        if (!mounted) return;

        final isGuest = FirebaseAuth.instance.currentUser == null;

        if (isGuest) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MoodDetailScreen(entry: updatedEntry),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AiRespondScreen(
                entry: updatedEntry,
                aiData: aiResult,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: const Color(0xFFE24B4A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mood = _moods[_selectedMood];
    final moodColor = mood['color'] as Color;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Entry' : 'Log Mood'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 28),

              if (widget.isEditing)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 13, color: Color(0xFFBA7517)),
                      SizedBox(width: 4),
                      Text(
                        'Editing existing entry',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF633806),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: moodColor,
                  height: 1.3,
                ),
                child: Text(
                  widget.isEditing
                      ? 'Update your\nfeeling'
                      : 'How are you\nfeeling today',
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),

              ScaleTransition(
                scale: _emojiScale,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: Text(
                    mood['emoji'] as String,
                    key: ValueKey(_selectedMood),
                    style: const TextStyle(fontSize: 52),
                  ),
                ),
              ),

              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: moodColor,
                ),
                child: Text(mood['label'] as String),
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final m = _moods[i];
                  final selected = _selectedMood == i;

                  return GestureDetector(
                    onTap: () => _selectMood(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected
                            ? (m['color'] as Color).withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: selected
                            ? Border.all(
                                color: (m['color'] as Color).withOpacity(0.4),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            m['emoji'] as String,
                            style: TextStyle(fontSize: selected ? 30 : 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m['label'] as String,
                            style: TextStyle(
                              fontSize: 9,
                              color: selected
                                  ? (m['color'] as Color)
                                  : const Color(0xFFB4B2A9),
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: _textCtrl,
                    maxLines: null,
                    expands: true,
                    autofocus: widget.isEditing,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                      height: 1.6,
                    ),
                    decoration: const InputDecoration(
                      hintText:
                          'Add a note... What happened today? How did it make you feel?',
                      hintStyle: TextStyle(
                        color: Color(0xFFB4B2A9),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    elevation: 0,
                    disabledBackgroundColor:
                        const Color(0xFF1D9E75).withOpacity(0.6),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          widget.isEditing ? Icons.check : Icons.save_outlined,
                          size: 20,
                        ),
                  label: Text(
                    _isSaving
                        ? (widget.isEditing ? 'Updating...' : 'Analyzing...')
                        : (widget.isEditing
                            ? 'Update Entry'
                            : 'Save My Details'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}