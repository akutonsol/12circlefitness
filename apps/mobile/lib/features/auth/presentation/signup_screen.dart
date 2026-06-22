import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/auth_provider.dart';

class _C {
  static const bg           = Color(0xFF0E0E0F);
  static const primaryCont  = Color(0xFFDDB7FF);
  static const deepPurple   = Color(0xFF842BD2);
  static const onSurface    = Color(0xFFE5E2E3);
  static const onSurfaceVar = Color(0xFFCDC3D0);
  static const outline      = Color(0xFF968E99);
  static const outlineVar   = Color(0xFF4B444F);
}

enum _Role { client, coach, vendor, admin }

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _firstCtrl    = TextEditingController();
  final _lastCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePass   = true;
  bool _agreedToTerms = false;
  _Role _selectedRole = _Role.client;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_firstCtrl.text.trim().isEmpty || _lastCtrl.text.trim().isEmpty) {
      _showError('Please enter your first and last name');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      _showError('Please enter your email address');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (!_agreedToTerms) {
      _showError('Please agree to the Terms of Service');
      return;
    }

    await ref.read(authNotifierProvider.notifier).signUp(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      firstName: _firstCtrl.text.trim(),
      lastName: _lastCtrl.text.trim(),
      role: _selectedRole.name,
    );

    final state = ref.read(authNotifierProvider);
    state.whenOrNull(
      error: (e, _) => _showError(e.toString()),
      data: (_) async {
        if (!mounted) return;
        final role = _selectedRole.name;
        if (role == 'coach') {
          context.go('/coach-dashboard');
        } else if (role == 'admin') {
          context.go('/admin-dashboard');
        } else if (role == 'vendor') {
          context.go('/vendor-portal');
        } else {
          context.go('/intake');
        }
      },
    );
  }

  // OAuth uses Supabase's redirect flow: the page navigates to the provider and
  // back, then the auth-state listener routes the signed-in user (new users →
  // /intake via the router guard). We only surface a launch error here.
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
                  stops: [0.0, 0.55, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // ── Bottom gradient ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: size.height * 0.75,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xE50E0E0F), Color(0xFF0E0E0F)],
                  stops: [0.0, 0.3, 0.6],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Back
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Icon(Icons.arrow_back, color: _C.primaryCont, size: 24),
                  ),
                  const SizedBox(height: 24),

                  // Headline
                  const Text('JOIN THE CIRCLE',
                    style: TextStyle(
                      color: _C.primaryCont, fontSize: 40,
                      fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -1.0,
                    )),
                  const SizedBox(height: 8),
                  const Text('Start your journey today.',
                    style: TextStyle(color: _C.onSurfaceVar, fontSize: 16, fontWeight: FontWeight.w400)),
                  const SizedBox(height: 28),

                  // Name row
                  Row(
                    children: [
                      Expanded(child: _InputField(controller: _firstCtrl, hint: 'First name')),
                      const SizedBox(width: 12),
                      Expanded(child: _InputField(controller: _lastCtrl, hint: 'Last name')),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Email
                  _InputField(
                    controller: _emailCtrl,
                    hint: 'Email address',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),

                  // Password
                  _PasswordField(
                    controller: _passwordCtrl,
                    obscure: _obscurePass,
                    onToggle: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  const SizedBox(height: 24),

                  // Role
                  const Text('I AM A:',
                    style: TextStyle(color: _C.primaryCont, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 2.0)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _RoleChip(label: 'Client', selected: _selectedRole == _Role.client,
                        onTap: () => setState(() => _selectedRole = _Role.client))),
                      const SizedBox(width: 8),
                      Expanded(child: _RoleChip(label: 'Coach', selected: _selectedRole == _Role.coach,
                        onTap: () => setState(() => _selectedRole = _Role.coach))),
                      const SizedBox(width: 8),
                      Expanded(child: _RoleChip(label: 'Vendor', selected: _selectedRole == _Role.vendor,
                        onTap: () => setState(() => _selectedRole = _Role.vendor))),
                      const SizedBox(width: 8),
                      Expanded(child: _RoleChip(label: 'Admin', selected: _selectedRole == _Role.admin,
                        onTap: () => setState(() => _selectedRole = _Role.admin))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Terms
                  GestureDetector(
                    onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _agreedToTerms ? _C.deepPurple : Colors.transparent,
                            border: Border.all(
                              color: _agreedToTerms ? _C.deepPurple : _C.outlineVar,
                              width: 1.5,
                            ),
                          ),
                          child: _agreedToTerms
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Text('I agree to the ',
                          style: TextStyle(color: _C.onSurfaceVar, fontSize: 14)),
                        GestureDetector(
                          onTap: () {},
                          child: const Text('Terms of Service',
                            style: TextStyle(color: _C.primaryCont,
                              fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Create Account button
                  GestureDetector(
                    onTap: isLoading ? null : _createAccount,
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
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
                          : const Text('Create Account',
                              style: TextStyle(color: Colors.white, fontSize: 16,
                                fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // OR
                  Row(
                    children: [
                      Expanded(child: Divider(color: _C.outlineVar.withValues(alpha: 0.3), thickness: 1)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: _C.outline, fontSize: 11,
                          fontWeight: FontWeight.w600, letterSpacing: 2)),
                      ),
                      Expanded(child: Divider(color: _C.outlineVar.withValues(alpha: 0.3), thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Google
                  _SocialButton(label: 'CONTINUE WITH GOOGLE', icon: _GoogleIcon(), onTap: isLoading ? () {} : _signInWithGoogle),
                  const SizedBox(height: 12),

                  // Apple
                  _SocialButton(
                    label: 'CONTINUE WITH APPLE',
                    icon: const Icon(Icons.apple, color: Colors.white, size: 22),
                    onTap: isLoading ? () {} : _signInWithApple,
                  ),
                  const SizedBox(height: 32),

                  // Sign in
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ',
                        style: TextStyle(color: _C.onSurfaceVar, fontSize: 14)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: const Text('SIGN IN',
                          style: TextStyle(color: _C.primaryCont, fontSize: 14,
                            fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                      ),
                    ],
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

// ── Widgets ───────────────────────────────────────────────────────────────────
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
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: _C.onSurface, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _C.outline, fontSize: 15),
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
  const _PasswordField({required this.controller, required this.obscure, required this.onToggle});

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
            style: const TextStyle(color: _C.onSurface, fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(color: _C.outline, fontSize: 15),
              border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
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

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: selected ? const LinearGradient(
            colors: [_C.deepPurple, _C.primaryCont],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ) : null,
          color: selected ? null : const Color(0xFF1C1B1C),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFF2A2A2B), width: 1),
          boxShadow: selected
              ? [const BoxShadow(color: Color(0x55842BD2), blurRadius: 12, offset: Offset(0, 4))]
              : null,
        ),
        child: Text(label,
          style: TextStyle(
            color: selected ? Colors.white : _C.onSurfaceVar,
            fontSize: 14, fontWeight: FontWeight.w700,
          )),
      ),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon, const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13,
              fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ],
        ),
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
      child: const Text('G',
        style: TextStyle(color: Color(0xFF4285F4), fontSize: 13, fontWeight: FontWeight.w800)),
    );
  }
}
