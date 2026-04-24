import 'package:flutter/material.dart';
import 'dart:async';
import '../screens/home_screen.dart';
import '../utils/transitions.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';

class MeditationScreen extends StatefulWidget {
  final bool fromWellness;
  const MeditationScreen({super.key, this.fromWellness = false});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalSeconds = 10 * 60;
  int _remainingSeconds = _totalSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isCompleted = false;
  int _currentStep = 0;

  final List<String> _steps = [
    'Find a comfortable position, close your eyes, and relax your shoulders.',
    'Breathe in slowly through your nose for 4 counts.',
    'Hold your breath gently for 4 counts.',
    'Exhale fully through your mouth for 6 counts.',
    'Let your thoughts pass like clouds — observe, don\'t engage.',
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
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

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remainingSeconds <= 0) {
          t.cancel();
          setState(() {
            _isRunning = false;
            _isCompleted = true;
          });
        } else {
          setState(() {
            _remainingSeconds--;
            final progress = 1 - (_remainingSeconds / _totalSeconds);
            _currentStep =
                (progress * _steps.length).floor().clamp(0, _steps.length - 1);
          });
        }
      });
    }
  }

  String get _timeDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => 1 - (_remainingSeconds / _totalSeconds);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF534AB7),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleBack,
        ),
        title: const Text(
          'Recommended Activity',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF534AB7),
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guided Meditation',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '10 min · Calm your mind',
                  style: TextStyle(
                      fontSize: 13, color: Colors.white.withOpacity(0.75)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isRunning ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                const Color(0xFF534AB7).withOpacity(0.12),
                            border: Border.all(
                              color:
                                  const Color(0xFF534AB7).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.self_improvement,
                              size: 44, color: Color(0xFF534AB7)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF534AB7).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(_timeDisplay,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF534AB7),
                            fontFeatures: [FontFeature.tabularFigures()],
                          )),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE0E0E0),
                            valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF534AB7)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _isCompleted ? null : _toggleTimer,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _isCompleted
                                ? Colors.grey
                                : const Color(0xFF534AB7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                              _isRunning ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('STEPS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF888780),
                        letterSpacing: 1.2)),
                const SizedBox(height: 12),
                ...List.generate(_steps.length, (i) {
                  final isDone = i < _currentStep;
                  final isCurrent = i == _currentStep;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone || isCurrent
                                ? const Color(0xFF534AB7)
                                : const Color(0xFFE8E8E8),
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : Text('${i + 1}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isCurrent
                                            ? Colors.white
                                            : const Color(0xFF888780))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: (isDone || isCurrent)
                                    ? const Color(0xFF1A1A2E)
                                    : const Color(0xFFB4B2A9)),
                            child: Text(_steps[i]),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<ActivityProvider>().logActivity(
                        activityName: 'Guided Meditation', 
                      );
                      _handleBack();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCompleted
                          ? const Color(0xFF534AB7)
                          : const Color(0xFF534AB7).withOpacity(0.4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27)),
                      elevation: 0,
                    ),
                    icon:
                        const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      _isCompleted
                          ? 'Activity Complete!'
                          : 'Mark as Complete',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
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
}