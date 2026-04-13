import 'package:flutter/material.dart';
import '../utils/transitions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signin_screen.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardPage(
      emoji: '📔',
      title: 'Your Personal\nEmotional Diary',
      subtitle:
          'Write freely about your day. No judgment, no pressure — just a safe space for your thoughts.',
      color: Color(0xFF1D9E75),
      bgColor: Color(0xFFE1F5EE),
    ),
    _OnboardPage(
      emoji: '🤖',
      title: 'AI That Actually\nUnderstands You',
      subtitle:
          'Our AI reads between the lines — detecting hidden patterns and triggers across your entries over time.',
      color: Color(0xFF534AB7),
      bgColor: Color(0xFFEEEDFE),
    ),
    _OnboardPage(
      emoji: '📊',
      title: 'Track Your\nEmotional Journey',
      subtitle:
          'Beautiful charts and weekly summaries show exactly how your mood evolves and what influences it.',
      color: Color(0xFF378ADD),
      bgColor: Color(0xFFE6F1FB),
    ),
    _OnboardPage(
      emoji: '🧘',
      title: 'Proactive\nWell-being Support',
      subtitle:
          'Before stress builds up, the app suggests breathing exercises and activities tailored just for you.',
      color: Color(0xFFBA7517),
      bgColor: Color(0xFFFAEEDA),
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      fadeScaleRoute(const SignInScreen()),
    );
  }

  void _skip() => _finish();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: page.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skip,
                  child: Text('Skip',
                      style: TextStyle(
                          color: page.color.withOpacity(0.7), fontSize: 14)),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (ctx, i) => _pages[i],
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? page.color
                        : page.color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: page.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27)),
                    elevation: 0,
                  ),
                  child: Text(
                    isLast ? "Let's Begin 🚀" : 'Next',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            if (!isLast) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _skip,
                child: Text('Continue as Guest',
                    style: TextStyle(
                        fontSize: 13,
                        color: page.color.withOpacity(0.6))),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;

  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big emoji illustration
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 64)),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: color.withOpacity(0.75),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
