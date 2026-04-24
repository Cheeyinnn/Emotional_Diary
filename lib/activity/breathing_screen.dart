import 'dart:math';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../utils/transitions.dart';
import '../screens/wellness_screen.dart';
import '../providers/activity_provider.dart';

enum BreathPhase { inhale, holdIn, exhale, holdOut }

class BreathingScreen extends StatefulWidget {
  final bool fromWellness;
  const BreathingScreen({super.key, this.fromWellness = false});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnim;

  BreathPhase _phase = BreathPhase.inhale;
  int _countdown = 4;
  int _cyclesCompleted = 0;
  bool _running = false;

  // Box breathing: 4-4-4-4
  static const _phaseDuration = {
    BreathPhase.inhale: 4,
    BreathPhase.holdIn: 4,
    BreathPhase.exhale: 4,
    BreathPhase.holdOut: 4,
  };

  static const _phaseLabel = {
    BreathPhase.inhale: 'Inhale',
    BreathPhase.holdIn: 'Hold',
    BreathPhase.exhale: 'Exhale',
    BreathPhase.holdOut: 'Hold',
  };

  static const _phaseColor = {
    BreathPhase.inhale: Color(0xFF1D9E75),
    BreathPhase.holdIn: Color(0xFF378ADD),
    BreathPhase.exhale: Color(0xFF534AB7),
    BreathPhase.holdOut: Color(0xFFBA7517),
  };

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
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

  void _start() {
    setState(() {
      _running = true;
      _phase = BreathPhase.inhale;
      _countdown = 4;
      _cyclesCompleted = 0;
    });
    _runPhase();
  }

  void _stop() {
    _scaleController.stop();
    setState(() => _running = false);
  }

  Future<void> _runPhase() async {
    if (!mounted || !_running) return;

    final duration = _phaseDuration[_phase]!;

    // Animate scale
    if (_phase == BreathPhase.inhale) {
      _scaleController.forward(from: 0);
    } else if (_phase == BreathPhase.exhale) {
      _scaleController.reverse(from: 1);
    }

    for (int i = duration; i >= 1; i--) {
      if (!mounted || !_running) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted || !_running) return;

    // Advance to next phase
    final phases = BreathPhase.values;
    final nextIdx = (phases.indexOf(_phase) + 1) % phases.length;
    final nextPhase = phases[nextIdx];

    if (nextPhase == BreathPhase.inhale) {
      setState(() => _cyclesCompleted++);
      if (_cyclesCompleted >= 4) {
        setState(() => _running = false);
        context.read<ActivityProvider>().logActivity(
          activityName: 'Box Breathing',
        );
        return;
      }
    }

    setState(() => _phase = nextPhase);
    _runPhase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _phaseColor[_phase]!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: _handleBack,
        ),
        title: const Text('Box Breathing',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text('4 - 4 - 4 - 4 technique',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const Spacer(),

            // Animated breathing circle
            AnimatedBuilder(
              animation: Listenable.merge([_scaleAnim, _rotateController]),
              builder: (ctx, _) {
                return SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: _rotateController.value * 2 * pi,
                        child: CustomPaint(
                          size: const Size(260, 260),
                          painter: _RingPainter(color: color.withOpacity(0.3)),
                        ),
                      ),
                      Transform.scale(
                        scale: _scaleAnim.value,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.15),
                            border: Border.all(
                                color: color.withOpacity(0.6), width: 2),
                          ),
                        ),
                      ),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.25),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _running
                                  ? _phaseLabel[_phase]!
                                  : _cyclesCompleted >= 4
                                      ? 'Done! 🎉'
                                      : 'Ready',
                              key: ValueKey(_phase.toString() + _running.toString()),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          if (_running) ...[
                            const SizedBox(height: 6),
                            Text(
                              _countdown.toString(),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const Spacer(),

            // Cycle progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text('Cycles: $_cyclesCompleted / 4',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: i < _cyclesCompleted
                              ? const Color(0xFF1D9E75)
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Phase guide
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: BreathPhase.values.map((p) {
                  final isActive = _phase == p && _running;
                  return _PhaseChip(
                    label: _phaseLabel[p]!,
                    seconds: _phaseDuration[p]!,
                    color: _phaseColor[p]!,
                    active: isActive,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),

            // Start/Stop button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _running ? _stop : _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _running
                        ? Colors.white12
                        : const Color(0xFF1D9E75),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27)),
                    elevation: 0,
                  ),
                  child: Text(
                    _running
                        ? 'Stop'
                        : _cyclesCompleted >= 4
                            ? 'Start Again'
                            : 'Start',
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

class _PhaseChip extends StatelessWidget {
  final String label;
  final int seconds;
  final Color color;
  final bool active;

  const _PhaseChip({
    required this.label,
    required this.seconds,
    required this.color,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.2) : Colors.white10,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? color : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: active ? color : Colors.white38,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${seconds}s',
              style: TextStyle(
                  fontSize: 13,
                  color: active ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  _RingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    for (int i = 0; i < 24; i++) {
      final startAngle = (i * 15) * pi / 180;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        8 * pi / 180,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color;
}