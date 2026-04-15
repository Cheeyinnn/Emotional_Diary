import 'dart:async';
import 'package:flutter/material.dart';

class MindfulWalkScreen extends StatefulWidget {
  const MindfulWalkScreen({super.key});

  @override
  State<MindfulWalkScreen> createState() => _MindfulWalkScreenState();
}

class _MindfulWalkScreenState extends State<MindfulWalkScreen>
    with TickerProviderStateMixin {
  static const _steps = [
    ('👀', 'See', '5 things you can see around you'),
    ('🖐️', 'Touch', '4 things you can physically feel'),
    ('👂', 'Hear', '3 things you can hear right now'),
    ('👃', 'Smell', '2 things you can smell'),
    ('👅', 'Taste', '1 thing you can taste'),
  ];

  int _stepIndex = 0;
  int _elapsed = 0;
  bool _running = false;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() {
        _running = true;
        _stepIndex = 0;
        _elapsed = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed++);
      });
    }
  }

  void _nextStep() {
    if (_stepIndex < _steps.length - 1) {
      setState(() => _stepIndex++);
    } else {
      _timer?.cancel();
      setState(() => _running = false);
    }
  }

  String get _timeLabel {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    const accent = Color(0xFF1D9E75);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Mindful Walk',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text('5-4-3-2-1 Grounding technique',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const Spacer(),

            // Pulse circle with emoji
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _running ? _pulseAnim.value : 1.0,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.12),
                    border: Border.all(
                        color: accent.withOpacity(0.5), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(step.$1,
                          style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text(step.$2,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: accent)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Instruction text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(step.$3,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5)),
            ),

            const Spacer(),

            // Step dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _stepIndex ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i <= _stepIndex ? accent : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),

            const SizedBox(height: 16),

            // Timer
            Text(_timeLabel,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 13,
                    fontFamily: 'monospace')),

            const SizedBox(height: 24),

            // Next step button (only while running)
            if (_running)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _nextStep,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: const BorderSide(color: accent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                    child: Text(
                      _stepIndex < _steps.length - 1
                          ? 'Next  →'
                          : 'Finish ✓',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Start/Stop
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _toggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _running ? Colors.white12 : accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27)),
                    elevation: 0,
                  ),
                  child: Text(
                    _running ? 'Stop' : 'Start Walk',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}