import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CheckinFormScreen extends ConsumerWidget {
  const CheckinFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      body: SafeArea(
        child: Column(children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).canPop()
                  ? Navigator.of(context).pop()
                  : context.go('/activity')),
            const Expanded(child: Center(child: Text("CHECK-IN",
              style: TextStyle(color: Color(0xFFDDB7FF), fontSize: 16,
                fontWeight: FontWeight.w800, letterSpacing: 2)))),
            const SizedBox(width: 48),
          ]),
          Expanded(child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("Check-In Form",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/daily-checkin'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7)),
                child: const Text("Go to Daily Check-In")),
            ]))),
        ])));
  }
}
