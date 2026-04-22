import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../utils/transitions.dart';

class CreativeExpressionScreen extends StatefulWidget {
  final bool fromWellness;
  const CreativeExpressionScreen({super.key, this.fromWellness = false});

  @override
  State<CreativeExpressionScreen> createState() =>
      _CreativeExpressionScreenState();
}

class _CreativeExpressionScreenState extends State<CreativeExpressionScreen> {
  final _controller = TextEditingController();
  int _promptIndex = 0;
  bool _done = false;

  static const _prompts = [
    'If your mood were a colour today, what would it look like and why?',
    'Describe your day as a weather forecast.',
    'Write a letter to your future self — just for today.',
    'If this feeling were a character in a story, what would it say?',
    'What song title best captures how you feel right now?',
  ];

  static const _accent = Color(0xFF534AB7);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _newPrompt() {
    setState(() {
      _promptIndex = (_promptIndex + 1) % _prompts.length;
      _controller.clear();
    });
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Write something — anything goes ✍️'),
          backgroundColor: Color(0xFF534AB7),
        ),
      );
      return;
    }
    setState(() => _done = true);
  }

  void _handleBack() {
    if (widget.fromWellness) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        fadeScaleRoute(const HomeScreen()),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: _handleBack,
        ),
        title: const Text('Creative Expression',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _done ? _buildDone() : _buildWrite(),
      ),
    );
  }

  Widget _buildWrite() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Center(
            child: Text('No rules. No judgement.\nJust you and your words.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white54, fontSize: 13, height: 1.5)),
          ),
          const SizedBox(height: 28),

          // Prompt card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accent.withOpacity(0.4), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: _accent, size: 16),
                    const SizedBox(width: 6),
                    const Text('PROMPT',
                        style: TextStyle(
                            color: _accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _newPrompt,
                      child: const Text('Try another →',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_prompts[_promptIndex],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Text input
          Container(
            constraints: const BoxConstraints(minHeight: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12, width: 1),
            ),
            child: TextField(
              controller: _controller,
              maxLines: null,
              autofocus: false,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.7),
              decoration: const InputDecoration(
                hintText: 'Start writing...',
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27)),
                elevation: 0,
              ),
              child: const Text('Save Expression',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✍️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            const Text('Expression Saved',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text(
                'Putting feelings into words\nis a powerful act of self-care.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white54, fontSize: 14, height: 1.6)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: _accent.withOpacity(0.3), width: 1),
              ),
              child: Text(_controller.text,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.6)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                  elevation: 0,
                ),
                child: const Text('Done', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}