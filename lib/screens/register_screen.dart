import 'package:flutter/material.dart';
import '../utils/transitions.dart';
import '../services/auth_service.dart';
import 'signin_screen.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
  final name = _nameCtrl.text.trim();
  final email = _emailCtrl.text.trim();
  final password = _passCtrl.text.trim();
  final confirmPassword = _confirmCtrl.text.trim();

  if (name.isEmpty ||
      email.isEmpty ||
      password.isEmpty ||
      confirmPassword.isEmpty) {
    _showSnackBar('Please fill in all fields.');
    return;
  }

  if (!email.contains('@') || !email.contains('.')) {
    _showSnackBar('Please enter a valid email address.');
    return;
  }

  if (password != confirmPassword) {
    _showSnackBar('Passwords do not match.');
    return;
  }

  if (password.length < 6) {
    _showSnackBar('Password must be at least 6 characters.');
    return;
  }

  setState(() => _isLoading = true);

  try {
    await _authService.register(name, email, password);

    if (!mounted) return;

    // ✅ ONLY register new account will bring guest data
    await context.read<DiaryProvider>().migrateGuestEntriesToCurrentUser();

    if (!mounted) return;

    _showSnackBar(
      'Verification email sent. Please verify your email before signing in.',
    );

    Navigator.of(context).pushReplacement(
      fadeScaleRoute(const SignInScreen()),
    );
  } catch (e) {
    String message = 'Registration failed. Please try again.';

    if (e == 'email-already-in-use') {
      message = 'This email is already registered.';
    } else if (e == 'invalid-email') {
      message = 'Please enter a valid email address.';
    } else if (e == 'weak-password') {
      message = 'Password is too weak.';
    } else if (e == 'firestore-save-failed') {
      message = 'Account created, but profile save failed.';
    }

    _showSnackBar(message);
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
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
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign up to begin your mindful journey',
                style: TextStyle(fontSize: 14, color: Color(0xFF888780)),
              ),
              const SizedBox(height: 40),

              _label('FULL NAME'),
              const SizedBox(height: 8),
              _inputField(
                controller: _nameCtrl,
                hint: 'Your full name',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 20),
              _label('EMAIL ADDRESS'),
              const SizedBox(height: 8),
              _inputField(
                controller: _emailCtrl,
                hint: 'yourname@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),
              _label('PASSWORD'),
              const SizedBox(height: 8),
              _inputField(
                controller: _passCtrl,
                hint: '••••••••',
                icon: Icons.lock_outlined,
                obscure: _obscurePass,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: const Color(0xFF888780),
                  ),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
              ),

              const SizedBox(height: 20),
              _label('CONFIRM PASSWORD'),
              const SizedBox(height: 8),
              _inputField(
                controller: _confirmCtrl,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: const Color(0xFF888780),
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    fadeScaleRoute(const SignInScreen()),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                        color: Color(0xFF888780),
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: Color(0xFF1D9E75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
          letterSpacing: 0.8,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB4B2A9)),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF888780)),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}