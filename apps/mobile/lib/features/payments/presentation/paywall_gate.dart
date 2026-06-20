import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/entitlements.dart';
import '../../auth/domain/auth_provider.dart';

const _bg    = Color(0xFF030303);
const _brand = Color(0xFFA855F7);
const _white = Colors.white;
const _muted = Color(0xFFCFC2D6);

/// Wraps a screen that requires at least [required]. Free/under-tier users see
/// an upgrade prompt instead of the gated content. Used at the router level so
/// the gated screens themselves stay plan-agnostic.
class PaywallGate extends ConsumerWidget {
  final ClientPlan required;
  final String featureName;
  final Widget child;
  const PaywallGate({
    super.key,
    required this.required,
    required this.featureName,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Coaches always have access to coaching tools (their plan is a coach plan,
    // not a client plan) — never paywall them.
    final isCoach = ref.watch(currentUserProfileProvider).valueOrNull?['role'] == 'coach';
    if (isCoach) return child;
    final planAsync = ref.watch(clientPlanProvider);
    return planAsync.when(
      loading: () => const Scaffold(
          backgroundColor: _bg,
          body: Center(child: CircularProgressIndicator(color: _brand))),
      error: (_, __) => child, // fail open rather than lock a paying user out
      data: (plan) =>
          plan.atLeast(required) ? child : _Locked(required: required, feature: featureName),
    );
  }
}

class _Locked extends StatelessWidget {
  final ClientPlan required;
  final String feature;
  const _Locked({required this.required, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_brand, Color(0xFF6D28D9)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: _brand.withValues(alpha: 0.4), blurRadius: 20),
                  ],
                ),
                child: const Icon(Icons.lock_rounded, color: _white, size: 34),
              ),
              const SizedBox(height: 20),
              Text('$feature is a ${required.label} feature',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                  'Upgrade your plan to unlock this and more.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 14, height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
                    foregroundColor: _white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => context.push('/upgrade'),
                  child: const Text('See Plans',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
