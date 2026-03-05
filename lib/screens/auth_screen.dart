import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/providers.dart';

/// Login-only screen for returning users.
/// New users go through OnboardingScreen which handles registration.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  static const _deep  = Color(0xFF880E4F);
  static const _mid   = Color(0xFFE91E63);
  static const _light = Color(0xFFF48FB1);
  static const _bg    = Color(0xFFFCE4EC);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  AuthService get _auth => ref.read(authServiceProvider);

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _auth.signInWithEmail(email: _emailCtrl.text, password: _passCtrl.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first, then tap Forgot Password.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _auth.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Password reset email sent!'),
          backgroundColor: _mid,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_deep, _mid, _light],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Faded hibiscus
          Positioned(
            top: -40, right: -40, width: 260, height: 260,
            child: Opacity(
              opacity: 0.18,
              child: Image.asset('assets/hibiscus.png', fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                // Logo + title
                const SizedBox(height: 16),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withAlpha(100), width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/hibiscus.png', fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.local_florist, color: Colors.white, size: 40)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Welcome Back',
                    style: TextStyle(color: Colors.white, fontSize: 26,
                        fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Log in to your account',
                    style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
                const SizedBox(height: 32),

                // Card
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Google button
                            OutlinedButton(
                              onPressed: _loading ? null : _googleSignIn,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFDDDDDD)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Center(child: Text('G',
                                        style: TextStyle(color: Colors.white,
                                            fontWeight: FontWeight.w800, fontSize: 14))),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Continue with Google',
                                      style: TextStyle(color: Color(0xFF333333),
                                          fontSize: 15, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                            Row(children: [
                              const Expanded(child: Divider(color: Color(0xFFEEEEEE))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('OR', style: TextStyle(color: Colors.grey.shade400,
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFEEEEEE))),
                            ]),
                            const SizedBox(height: 20),

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                                if (!v.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                prefixIcon: const Icon(Icons.email_outlined, color: _mid, size: 20),
                                filled: true, fillColor: _bg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _mid, width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please enter your password';
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                prefixIcon: const Icon(Icons.lock_outline, color: _mid, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: _mid, size: 20),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                                filled: true, fillColor: _bg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _mid, width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading ? null : _forgotPassword,
                                child: const Text('Forgot password?',
                                    style: TextStyle(color: _mid, fontSize: 13)),
                              ),
                            ),

                            // Error
                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(_error!,
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                    textAlign: TextAlign.center),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Login button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _mid,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: _light.withAlpha(100),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _loading
                                    ? const SizedBox(width: 22, height: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : const Text('Log In',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
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
