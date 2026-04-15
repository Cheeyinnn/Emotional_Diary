import 'package:flutter/material.dart';

class GratitudeJournalingScreen extends StatefulWidget {
  const GratitudeJournalingScreen({super.key});

  @override
  State<GratitudeJournalingScreen> createState() =>
      _GratitudeJournalingScreenState();
}

class _GratitudeJournalingScreenState
    extends State<GratitudeJournalingScreen> {
  final _controllers = List.generate(3, (_) => TextEditingController());
  bool _done = false;

  static const _prompts = [
    'Something that made you smile today…',
    'A person you are grateful for…',
    'A small thing you often overlook…',
  ];

  static const _accent = Color(0xFFEF9F27);

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final filled = _controllers.every((c) => c.text.trim().isNotEmpty);
    if (!filled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all three gratitudes ✨'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
      return;
    }
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gratitude Journaling',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _done ? _buildDone() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
         Text('Gratitude shifts your focus\nfrom what\'s missing to what\'s present.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white54, fontSize: 13, height: 1.5)),
        const SizedBox(height: 32),

        ...List.generate(3, (i) => _buildCard(i)),

        const SizedBox(height: 32),
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
            child: const Text('Save Gratitudes',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.2),
                ),
                child: Center(
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_prompts[i],
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controllers[i],
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Write here...',
              hintStyle: TextStyle(color: Colors.white30),
              border: InputBorder.none,
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
            const Text('🌟', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            const Text('Gratitudes Saved',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text(
              'You\'ve taken a moment to appreciate the good.\nThat matters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),

            // Show what they wrote
            ...List.generate(3, (i) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _accent.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Text('🙏',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_controllers[i].text,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                  elevation: 0,
                ),
                child: const Text('Done',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}