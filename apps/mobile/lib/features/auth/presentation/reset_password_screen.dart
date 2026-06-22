import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart' show passwordRecoveryNotifier;

/// Reached after the user taps the password-reset link in their email. Supabase
/// establishes a short-lived recovery session and fires AuthChangeEvent
/// .passwordRecovery; the router sends them here to set a new password.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _pwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _done = false;
  bool _obscure = true;

  @override
  void dispose() {
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pw = _pwCtrl.text;
    final confirm = _confirmCtrl.text;
    if (pw.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }
    if (pw != confirm) {
      _snack('Passwords do not match');
      return;
    }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: pw));
      passwordRecoveryNotifier.value = false;
      if (mounted) setState(() { _loading = false; _done = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack(e.toString());
      }
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _done
              ? _buildDone()
              : SingleChildScrollView(child: _buildForm()),
        ),
      ),
    );
  }

  Widget _buildForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text('Set a new password',
              style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Choose a new password for your account.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 40),
          TextField(
            controller: _pwCtrl,
            obscureText: _obscure,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              hintText: 'New password',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textTertiary),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textTertiary),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmCtrl,
            obscureText: _obscure,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              hintText: 'Confirm new password',
              prefixIcon: Icon(Icons.lock_outline, color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Update Password'),
          ),
        ],
      );

  Widget _buildDone() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.2)),
            child: const Icon(Icons.check, color: AppColors.success, size: 40),
          ),
          const SizedBox(height: 24),
          const Text('Password updated',
              style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Your password has been changed. Sign in with your new password.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Back to Sign In'),
          ),
        ],
      );
}
