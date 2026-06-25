import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/auth_provider.dart';
import '../../../core/router/app_router.dart' show authErrorNotifier;
import 'widgets/auth_design.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

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

    await ref.read(authNotifierProvider.notifier).signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      _showError(authState.error.toString());
      return;
    }
    await _handlePostAuthNavigation();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AuthColors.purple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent));
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return AuthScaffold(
      title: 'Welcome Back',
      subtitle: 'Sign in to continue your fitness journey.',
      footer: AuthFooterLink(prefix: "Don't have an account?", action: 'Sign Up', onTap: () => context.go('/signup')),
      children: [
        AuthField(controller: _emailCtrl, hint: 'Email address', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        AuthField(controller: _passwordCtrl, hint: 'Password', isPassword: true),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: GestureDetector(
          onTap: () => context.go('/forgot-password'),
          child: const Text('Forgot password?',
            style: TextStyle(color: AuthColors.purpleLight, fontSize: 14, fontWeight: FontWeight.w600)))),
        const SizedBox(height: 22),
        AuthButton(label: 'Sign In', loading: isLoading, onTap: _signIn),
        const SizedBox(height: 22),
        const AuthDivider(),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: AuthSocialButton(label: 'Google', icon: const GoogleGlyph(),
            onTap: isLoading ? () {} : _signInWithGoogle)),
          const SizedBox(width: 12),
          Expanded(child: AuthSocialButton(label: 'Apple', icon: const Icon(Icons.apple, color: Colors.white, size: 22),
            onTap: isLoading ? () {} : _signInWithApple)),
        ]),
      ],
    );
  }
}
