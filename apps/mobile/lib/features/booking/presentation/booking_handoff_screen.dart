import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _bg    = Color(0xFF030303);
const _brand = Color(0xFFA855F7);
const _mint  = Color(0xFF6FFBBE);
const _white = Colors.white;
const _muted = Color(0xFFCFC2D6);

/// Shown right after a client subscribes to a coaching plan. A brief celebratory
/// loading beat, then it hands the client off to the booking module.
class BookingHandoffScreen extends StatefulWidget {
  const BookingHandoffScreen({super.key});
  @override
  State<BookingHandoffScreen> createState() => _BookingHandoffScreenState();
}

class _BookingHandoffScreenState extends State<BookingHandoffScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/appointments');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: _mint.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _mint.withValues(alpha: 0.25), blurRadius: 30)],
              ),
              child: const Icon(Icons.event_available_rounded, color: _mint, size: 46),
            ),
            const SizedBox(height: 28),
            const Text('You’re all set! 🎉',
                style: TextStyle(color: _white, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text('Time to book your sessions with your coach…',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 15, height: 1.4)),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(color: _brand, strokeWidth: 3)),
          ]),
        ),
      ),
    );
  }
}
