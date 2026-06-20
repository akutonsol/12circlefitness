import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LogMealScreen extends StatefulWidget {
  const LogMealScreen({super.key});
  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/meals-dashboard');
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF030303),
    body: Center(child: CircularProgressIndicator(color: Color(0xFFA855F7))));
}
