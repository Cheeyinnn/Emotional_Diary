import 'package:flutter/material.dart';
import 'home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _signIn() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
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
              const Text('Welcome Back',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 6),
              const Text('Sign in to continue your progress',
                  style: TextStyle(fontSize: 14, color: Color(0xFF888780))),
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
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                    color: const Color(0xFF888780),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _remember,
                        onChanged: (v) => setState(() => _remember = v!),
                        activeColor: const Color(0xFF1D9E75),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text('Remember Me',
                          style: TextStyle(fontSize: 13, color: Color(0xFF888780))),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Forgot Password?',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF1D9E75))),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27)),
                    elevation: 0,
                  ),
                  child: const Text('Sign In',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Color(0xFF888780), fontSize: 13),
                      children: [
                        TextSpan(
                          text: 'Back to Welcome',
                          style: TextStyle(
                              color: Color(0xFF1D9E75),
                              fontWeight: FontWeight.w600),
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
            letterSpacing: 0.8),
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
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
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
