import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'signin_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF3DE), Color(0xFFE1F5EE)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9E75),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.spa_outlined, color: Colors.white, size: 28),
                ),
                const Spacer(),
                // Tagline
                const Text(
                  'Find Your\nInner Calm',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF085041),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Take a deep breath and start\nyour mindful journey today.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF0F6E56),
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                // Page dots
                Row(
                  children: [
                    _dot(true),
                    const SizedBox(width: 6),
                    _dot(false),
                    const SizedBox(width: 6),
                    _dot(false),
                  ],
                ),
                const SizedBox(height: 32),
                // Get Started button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D9E75),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Get Started',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Continue as guest
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1D9E75),
                      side: const BorderSide(color: Color(0xFF1D9E75)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                    child: const Text('Continue as Guest',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(bool active) => Container(
        width: active ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF1D9E75)
              : const Color(0xFF1D9E75).withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      );
}
