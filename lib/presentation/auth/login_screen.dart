import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Color _background = Color(0xFF080B18);
  static const Color _cardColor = Color(0xFF101426);
  static const Color _borderColor = Color(0xFF303B68);

  static const Color _purple = Color(0xFF8B3DFF);
  static const Color _blue = Color(0xFF4E6CFF);
  static const Color _cyan = Color(0xFF19C9ED);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await _authService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final user = credential.user;

      debugPrint('LOGIN SUCCESS');
      debugPrint('User ID: ${user?.uid}');
      debugPrint('Email: ${user?.email}');

      _showMessage('Login successful.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString());
    } finally {
      // ignore: control_flow_in_finally,
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          Positioned(
            top: -180,
            left: -180,
            child: _GlowCircle(
              size: 420,
              color: _purple.withValues(alpha: 0.25),
            ),
          ),

          Positioned(
            bottom: -200,
            right: -160,
            child: _GlowCircle(size: 440, color: _blue.withValues(alpha: 0.22)),
          ),
          Positioned(
            top: 120,
            right: 80,
            child: _GlowCircle(size: 160, color: _cyan.withValues(alpha: 0.05)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: _buildLoginCard(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
          decoration: BoxDecoration(
            color: _cardColor.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _purple.withValues(alpha: 0.45),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 40,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: _purple.withValues(alpha: 0.08),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogo(),

              const SizedBox(height: 26),

              _buildTitle(),

              const SizedBox(height: 10),

              const Text(
                'Track  •  Analyze  •  Be More Productive',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9CA8C8),
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 38),

              _buildEmailField(),

              const SizedBox(height: 16),

              _buildPasswordField(),

              const SizedBox(height: 28),

              _buildLoginButton(),

              const SizedBox(height: 30),

              _buildSecureAccess(),

              const SizedBox(height: 32),

              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_purple, _blue, _cyan],
        ),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.28),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 50),
      ),
    );
  }

  Widget _buildTitle() {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        children: [
          TextSpan(
            text: 'Work Activity ',
            style: TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: 'Monitor',
            style: TextStyle(color: _purple),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return _buildTextField(
      controller: _emailController,
      hintText: 'Email address',
      icon: Icons.mail_outline_rounded,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordField() {
    return _buildTextField(
      controller: _passwordController,
      hintText: 'Password',
      icon: Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        tooltip: _obscurePassword ? 'Show password' : 'Hide password',
        onPressed: _isLoading
            ? null
            : () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: const Color(0xFF91A0C5),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF151B31),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: TextField(
        controller: controller,
        enabled: !_isLoading,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: _cyan,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF8995B6), fontSize: 16),
          prefixIcon: Icon(icon, color: _purple, size: 23),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_purple, _blue, _cyan],
          ),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: 0.25),
              blurRadius: 25,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    key: ValueKey('login'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded, size: 22),
                      SizedBox(width: 12),
                      Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecureAccess() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFF303852))),

        const SizedBox(width: 18),

        const Icon(Icons.shield_outlined, color: Color(0xFF91A0C5), size: 20),

        const SizedBox(width: 8),

        const Text(
          'Secure Access',
          style: TextStyle(
            color: Color(0xFF9CA8C8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(width: 18),

        Expanded(child: Container(height: 1, color: const Color(0xFF303852))),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 50, height: 1, color: const Color(0xFF3A425A)),
        const SizedBox(width: 16),
        const Text(
          'Your work matters. Track it.',
          style: TextStyle(
            color: Color(0xFF8995B6),
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 16),
        Container(width: 50, height: 1, color: const Color(0xFF3A425A)),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 30)],
      ),
    );
  }
}
