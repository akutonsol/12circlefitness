import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/auth_provider.dart';
import '../../../core/router/app_router.dart' show authErrorNotifier;

class _C {
  static const bg           = Color(0xFF0E0E0F);
  static const primaryCont  = Color(0xFFDDB7FF);
  static const deepPurple   = Color(0xFF842BD2);
  static const onSurface    = Color(0xFFE5E2E3);
  static const onSurfaceVar = Color(0xFFCDC3D0);
  static const outline      = Color(0xFF968E99);
  static const outlineVar   = Color(0xFF4B444F);
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePass   = true;

  @override
  void initState() {
    super.initState();
    // If an OAuth redirect came back with an error, main() stashed a message.
    // Show it once now that the login screen is up, then clear it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final msg = authErrorNotifier.value;
      if (msg != null && mounted) {
        authErrorNotifier.value = null;
        _showError(msg);
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePostAuthNavigation() async {
    if (!mounted) return;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final profile = await Supabase.instance.client
            .from('user_profiles')
            .select('role, onboarding_complete')
            .eq('id', userId)
            .maybeSingle();
        final role = profile?['role'] as String? ?? 'client';
        final needsOnboarding = profile?['onboarding_complete'] == false;
        if (!mounted) return;
        if (role == 'coach') {
          context.go('/coach-dashboard');
        } else if (role == 'admin') {
          context.go('/admin-dashboard');
        } else if (role == 'vendor') {
          context.go('/vendor-portal');
        } else if (needsOnboarding) {
          context.go('/intake');
        } else {
          context.go('/home');
        }
      } else {
        if (mounted) context.go('/home');
      }
    } catch (_) {
      if (mounted) context.go('/home');
    }
  }

  // OAuth uses Supabase's redirect flow: the page navigates to the provider and
  // back, then the auth-state listener + router handle navigation. We only
  // surface a launch error here.
  Future<void> _signInWithGoogle() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (mounted && ref.read(authNotifierProvider).hasError) {
      _showError('Could not start Google sign-in. Please try again.');
    }
  }

  Future<void> _signInWithApple() async {
    await ref.read(authNotifierProvider.notifier).signInWithApple();
    if (mounted && ref.read(authNotifierProvider).hasError) {
      _showError('Could not start Apple sign-in. Please try again.');
    }
  }

  Future<void> _signIn() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      _showError('Please enter your email and password');
      return;
    }

    await ref.read(authNotifierProvider.notifier).signIn(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      _showError(authState.error.toString());
      return;
    }

    await _handlePostAuthNavigation();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _C.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ));

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final size      = MediaQuery.of(context).size;
    final bottom    = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _C.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── Background ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/intro-bg-1.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (_, __, ___) => Container(color: _C.bg),
            ),
          ),

          // ── Left gradient ──
          Positioned.fill(
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0E0E0F), Color(0xCC0E0E0F), Colors.transparent],
                  stops: [0.0, 0.5, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // ── Bottom gradient ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: size.height * 0.65,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xE50E0E0F), Color(0xFF0E0E0F)],
                  stops: [0.0, 0.4, 0.7],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Top vignette ──
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.18,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0E0E0F), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(left: 20, right: 20, bottom: bottom + 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top - 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Logo
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        child: Image.asset('assets/images/12circle-logo.png',
                          height: 36, fit: BoxFit.contain),
                      ),
                    ),

                    SizedBox(height: size.height * 0.08),

                    // Headline
                    const Text("LET'S",
                      style: TextStyle(color: Colors.white, fontSize: 52,
                        fontWeight: FontWeight.w800, height: 1.0, letterSpacing: -1.5)),
                    const Text('CRUSH IT',
                      style: TextStyle(color: _C.primaryCont, fontSize: 52,
                        fontWeight: FontWeight.w800, height: 1.0, letterSpacing: -1.5)),
                    const SizedBox(height: 8),
                    const Text('Sign in to your account',
                      style: TextStyle(color: _C.onSurfaceVar, fontSize: 16,
                        fontWeight: FontWeight.w400)),
                    const SizedBox(height: 32),

                    // Email
                    _InputField(
                      controller: _emailCtrl,
                      hint: 'EMAIL ADDRESS',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    // Password
                    _PasswordField(
                      controller: _passwordCtrl,
                      obscure: _obscurePass,
                      onToggle: () => setState(() => _obscurePass = !_obscurePass),
                      onForgot: () => context.go('/forgot-password'),
                    ),
                    const SizedBox(height: 20),

                    // Sign In button
                    GestureDetector(
                      onTap: isLoading ? null : _signIn,
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [_C.deepPurple, _C.primaryCont],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color(0x73842BD2), blurRadius: 24, offset: Offset(0, 10)),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: isLoading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('SIGN IN',
                                style: TextStyle(color: Colors.white, fontSize: 15,
                                  fontWeight: FontWeight.w800, letterSpacing: 3)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // OR
                    Row(children: [
                      Expanded(child: Divider(color: _C.outlineVar.withValues(alpha: 0.3), thickness: 1)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: _C.outline, fontSize: 11,
                          fontWeight: FontWeight.w600, letterSpacing: 2)),
                      ),
                      Expanded(child: Divider(color: _C.outlineVar.withValues(alpha: 0.3), thickness: 1)),
                    ]),
                    const SizedBox(height: 24),

                    // Google
                    _SocialButton(label: 'CONTINUE WITH GOOGLE', icon: _GoogleIcon(), onTap: isLoading ? () {} : _signInWithGoogle),
                    const SizedBox(height: 12),

                    // Apple
                    _SocialButton(
                      label: 'CONTINUE WITH APPLE',
                      icon: const Icon(Icons.apple, color: Colors.white, size: 22),
                      onTap: isLoading ? () {} : _signInWithApple,
                    ),
                    const SizedBox(height: 40),

                    // Join footer
                    Column(children: [
                      Row(children: [
                        Expanded(child: Divider(color: _C.outlineVar.withValues(alpha: 0.25), thickness: 1)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('NEW TO THE CIRCLE?',
                            style: TextStyle(color: _C.outline, fontSize: 9,
                              fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                        ),
                        Expanded(child: Divider(color: _C.outlineVar.withValues(alpha: 0.25), thickness: 1)),
                      ]),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => context.go('/signup'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('JOIN THE COMMUNITY',
                              style: TextStyle(color: _C.primaryCont, fontSize: 14,
                                fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                            SizedBox(width: 6),
                            Text('→', style: TextStyle(color: _C.primaryCont, fontSize: 16,
                              fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final TextInputType keyboardType;
  const _InputField({required this.controller, required this.hint,
    this.icon, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2B), width: 1),
      ),
      child: Row(children: [
        const SizedBox(width: 16),
        if (icon != null) ...[Icon(icon, color: _C.outline, size: 20), const SizedBox(width: 12)],
        Expanded(
          child: TextField(
            controller: controller, keyboardType: keyboardType,
            style: const TextStyle(color: _C.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _C.outline, fontSize: 12,
                fontWeight: FontWeight.w600, letterSpacing: 1.5),
              border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ]),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final VoidCallback onForgot;
  const _PasswordField({required this.controller, required this.obscure,
    required this.onToggle, required this.onForgot});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2B), width: 1),
      ),
      child: Row(children: [
        const SizedBox(width: 16),
        const Icon(Icons.lock_outline, color: _C.outline, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller, obscureText: obscure,
            style: const TextStyle(color: _C.onSurface, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'PASSWORD',
              hintStyle: TextStyle(color: _C.outline, fontSize: 12,
                fontWeight: FontWeight.w600, letterSpacing: 1.5),
              border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        GestureDetector(
          onTap: onForgot,
          child: const Text('FORGOT?', style: TextStyle(color: _C.primaryCont,
            fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onToggle,
          child: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: _C.outline, size: 20),
        ),
        const SizedBox(width: 16),
      ]),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  const _SocialButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1B1C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2B), width: 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          icon, const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13,
            fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ]),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22, height: 22,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      alignment: Alignment.center,
      child: const Text('G', style: TextStyle(color: Color(0xFF4285F4),
        fontSize: 13, fontWeight: FontWeight.w800)),
    );
  }
}
