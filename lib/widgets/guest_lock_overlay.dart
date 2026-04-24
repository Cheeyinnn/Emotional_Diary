import 'dart:ui';

import 'package:flutter/material.dart';
import '../screens/register_screen.dart';
import '../utils/transitions.dart';

class GuestLockOverlay extends StatelessWidget {
  final String title;
  final String message;
  final String footer;

  const GuestLockOverlay({
    super.key,
    required this.title,
    required this.message,
    this.footer = 'Register to unlock this feature.',
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: Colors.black.withOpacity(0.35),
              ),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 42),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE1F5EE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF1D9E75),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF888780),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          fadeRoute(const RegisterScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Register Now',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    footer,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFFB4B2A9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}