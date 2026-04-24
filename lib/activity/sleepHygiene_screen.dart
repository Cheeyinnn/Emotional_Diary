import 'package:flutter/material.dart';
import 'dart:async';
import '../screens/home_screen.dart';
import '../utils/transitions.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';

class SleepHygieneScreen extends StatefulWidget {
  final bool fromWellness;
  const SleepHygieneScreen({super.key, this.fromWellness = false});

  @override
  State<SleepHygieneScreen> createState() => _SleepHygieneScreenState();
}

class _SleepHygieneScreenState extends State<SleepHygieneScreen> {
  static const int _totalSeconds = 8 * 60;
  int _remainingSeconds = _totalSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isCompleted = false;
  int _currentStep = 0;

  final List<String> _steps = [
    'Dim your screen brightness and put your phone face-down.',
    'Write down one thing you want to let go of before sleeping.',
    'Do a quick body scan — relax each muscle from head to toe.',
    'Set a consistent bedtime alarm for tomorrow.',
    'Close your eyes and take 5 slow, deep breaths.',
  ];

  @override
  void dispose() {
    _timer?.cancel();
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
    const color = Color(0xFF378ADD);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: color,
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
            color: color,
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sleep Hygiene',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('8 min · Wind down for better rest',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.75))),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.1),
                      border:
                          Border.all(color: color.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.bedtime_outlined,
                        size: 44, color: color),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.tips_and_updates_outlined,
                          color: color, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Consistent sleep schedules improve mood stability over time.',
                          style: TextStyle(
                              fontSize: 12, color: color, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(_timeDisplay,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: color,
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
                            valueColor: const AlwaysStoppedAnimation(color),
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
                            color: _isCompleted ? Colors.grey : color,
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
                                ? color
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
                        activityName: 'Sleep Hygiene', 
                      );
                      _handleBack();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isCompleted ? color : color.withOpacity(0.4),
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