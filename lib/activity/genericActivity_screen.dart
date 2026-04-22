import 'package:flutter/material.dart';
import 'dart:async';
import '../screens/home_screen.dart';
import '../utils/transitions.dart';


class GenericActivityScreen extends StatefulWidget {
  final String name;
  final String duration;
  final String steps;

  const GenericActivityScreen({
    super.key,
    required this.name,
    required this.duration,
    required this.steps,
    bool fromWellness = false,
  });

  @override
  State<GenericActivityScreen> createState() => _GenericActivityScreenState();
}

class _GenericActivityScreenState extends State<GenericActivityScreen> {
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isCompleted = false;
  int _currentStep = 0;

  List<String> get _steps => widget.steps
      .split('\n')
      .map((s) => s.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
      .where((s) => s.isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    _totalSeconds = _parseDuration(widget.duration);
    _remainingSeconds = _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _parseDuration(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    final minutes = int.tryParse(match?.group(1) ?? '10') ?? 10;
    return minutes * 60;
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
            // Auto-advance steps based on time
            final progress = 1 - (_remainingSeconds / _totalSeconds);
            final steps = _steps;
            if (steps.isNotEmpty) {
              _currentStep =
                  (progress * steps.length).floor().clamp(0, steps.length - 1);
            }
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

  double get _progress =>
      _totalSeconds == 0 ? 0 : 1 - (_remainingSeconds / _totalSeconds);

  @override
  Widget build(BuildContext context) {
    final steps = _steps;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            fadeScaleRoute(const HomeScreen()),
            (r) => false,
          ),
        ),
        title: const Text(
          'Recommended Activity',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      body: Column(
        children: [
          // Green header
          Container(
            color: const Color(0xFF1D9E75),
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.duration,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Timer card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9E75).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Time display
                      Text(
                        _timeDisplay,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D9E75),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Progress bar
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE0E0E0),
                            valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF1D9E75)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Play/Pause button
                      GestureDetector(
                        onTap: _isCompleted ? null : _toggleTimer,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _isCompleted
                                ? Colors.grey
                                : const Color(0xFF1D9E75),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isRunning ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Steps
                const Text(
                  'STEPS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF888780),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                ...List.generate(steps.length, (i) {
                  final isDone = i < _currentStep;
                  final isCurrent = i == _currentStep;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step number circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? const Color(0xFF1D9E75)
                                : isCurrent
                                    ? const Color(0xFF1D9E75)
                                    : const Color(0xFFE8E8E8),
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isCurrent
                                          ? Colors.white
                                          : const Color(0xFF888780),
                                    ),
                                  ),
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
                                  : const Color(0xFFB4B2A9),
                            ),
                            child: Text(steps[i]),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Complete button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      fadeScaleRoute(const HomeScreen()),
                      (r) => false,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCompleted
                          ? const Color(0xFF1D9E75)
                          : const Color(0xFF1D9E75).withOpacity(0.4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      _isCompleted ? 'Activity Complete!' : 'Mark as Complete',
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