import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../models/diary_entry.dart';
import 'ai_respond_screen.dart';

class LogMoodScreen extends StatefulWidget {
  const LogMoodScreen({super.key});

  @override
  State<LogMoodScreen> createState() => _LogMoodScreenState();
}

class _LogMoodScreenState extends State<LogMoodScreen> {
  int _selectedMood = 2; // default Okay
  final _textCtrl = TextEditingController();
  bool _isSaving = false;

  final _moods = [
    {'emoji': '😣', 'label': 'Awful', 'color': Color(0xFFE24B4A)},
    {'emoji': '😞', 'label': 'Bad', 'color': Color(0xFFEF9F27)},
    {'emoji': '😐', 'label': 'Okay', 'color': Color(0xFF888780)},
    {'emoji': '😊', 'label': 'Good', 'color': Color(0xFF1D9E75)},
    {'emoji': '😄test', 'label': 'Great', 'color': Color(0xFF378ADD)},
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final provider = context.read<DiaryProvider>();
    final entry = await provider.addEntry(
      entryText: _textCtrl.text.trim().isEmpty
          ? 'No note added.'
          : _textCtrl.text.trim(),
      mood: _selectedMood,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AiRespondScreen(entry: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mood = _moods[_selectedMood];
    final moodColor = mood['color'] as Color;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Log Mood'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Text(
                'How are you\nfeeling today',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: moodColor,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  mood['emoji'] as String,
                  key: ValueKey(_selectedMood),
                  style: const TextStyle(fontSize: 52),
                ),
              ),
              Text(
                mood['label'] as String,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: moodColor),
              ),
              const SizedBox(height: 28),

              // Emoji selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final m = _moods[i];
                  final selected = _selectedMood == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = i),
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
                                width: 1.5)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(m['emoji'] as String,
                              style: TextStyle(
                                  fontSize: selected ? 30 : 24)),
                          const SizedBox(height: 4),
                          Text(m['label'] as String,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: selected
                                      ? (m['color'] as Color)
                                      : const Color(0xFFB4B2A9),
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400)),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Text area
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFE0E0E0), width: 0.5),
                  ),
                  child: TextField(
                    controller: _textCtrl,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                        height: 1.6),
                    decoration: const InputDecoration(
                      hintText:
                          'Add a note... What happened today? How did it make you feel?',
                      hintStyle:
                          TextStyle(color: Color(0xFFB4B2A9), fontSize: 13),
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
                        borderRadius: BorderRadius.circular(27)),
                    elevation: 0,
                    disabledBackgroundColor:
                        const Color(0xFF1D9E75).withOpacity(0.6),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined, size: 20),
                  label: Text(
                    _isSaving ? 'Analyzing...' : 'Save My Details',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
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
