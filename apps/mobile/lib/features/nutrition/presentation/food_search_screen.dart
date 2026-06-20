import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});
  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
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
