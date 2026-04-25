import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/transitions.dart';
import '../services/auth_service.dart';
import '../providers/activity_provider.dart';
import '../providers/diary_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'welcome_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _goBackToWelcome() {
    Navigator.of(context).pushAndRemoveUntil(
      fadeScaleRoute(const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(email, password);

      if (!mounted) return;

      // Load activity logs from Firestore after sign in
      await context.read<ActivityProvider>().loadLogs();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        fadeScaleRoute(const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      String message = 'Sign in failed. Please try again.';

      if (e == 'user-not-found') {
        message = 'No account found for this email.';
      } else if (e == 'wrong-password' || e == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e == 'user-disabled') {
        message = 'This account has been disabled.';
      }

      _showSnackBar(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Enter your email first to reset password.');
      return;
    }

    try {
      await _authService.resetPassword(email);
      _showSnackBar('Password reset email sent.');
    } catch (e) {
      String message = 'Unable to send reset email.';

      if (e == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e == 'user-not-found') {
        message = 'No account found for this email.';
      }

      _showSnackBar(message);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goBackToWelcome();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: _goBackToWelcome,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to continue your progress',
                  style: TextStyle(fontSize: 14, color: Color(0xFF888780)),
                ),
                const SizedBox(height: 40),

                _label('EMAIL ADDRESS'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _emailCtrl,
                  hint: 'yourname@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),
                _label('SECURE PASSWORD'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _passCtrl,
                  hint: '••••••••',
                  icon: Icons.lock_outlined,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: const Color(0xFF888780),
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1D9E75),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF888780),
        ),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
    );
  }
}