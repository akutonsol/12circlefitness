import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/messaging_provider.dart';

const _bg      = Color(0xFF030303);
const _card    = Color(0xFF0E0B16);
const _border  = Color(0xFF1A1020);
const _brand   = Color(0xFFA855F7);
const _white   = Colors.white;
const _muted   = Color(0xFFCFC2D6);
const _primary = Color(0xFFDDB7FF);
const _green   = Color(0xFF22C55E);

class MessagingScreen extends ConsumerWidget {
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              color: _card,
              border: Border(bottom: BorderSide(color: _border))),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back, color: _white, size: 18))),
              const SizedBox(width: 12),
              const Expanded(
                child: Text("Messages",
                  style: TextStyle(color: _white, fontSize: 19, fontWeight: FontWeight.w700))),
              GestureDetector(
                onTap: () => ref.invalidate(conversationsProvider),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle),
                  child: const Icon(Icons.refresh, color: _white, size: 18))),
            ])),

          // ── Body ──
          Expanded(
            child: convsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _brand)),
              error: (_, __) => _EmptyState(
                icon: Icons.wifi_off_outlined,
                message: "Couldn't load messages",
                sub: "Tap refresh to try again"),
              data: (convs) {
                if (convs.isEmpty) {
                  return _EmptyState(
                    icon: Icons.chat_bubble_outline,
                    message: "No conversations yet",
                    sub: "Your messages with coaches and clients will appear here");
                }
                return RefreshIndicator(
                  color: _brand,
                  backgroundColor: _card,
                  onRefresh: () async => ref.invalidate(conversationsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: convs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ConversationTile(
                      conv: convs[i],
                      onTap: () {
                        ref.read(selectedConversationProvider.notifier).state = convs[i];
                        context.go('/chat');
                      })));
              })),
        ])));
  }
}

// ── Conversation Tile ─────────────────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conv;
  final VoidCallback onTap;
  const _ConversationTile({required this.conv, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final participant = conv['participant'] as Map<String, dynamic>?;
    final fn = participant?['first_name'] as String? ?? '';
    final ln = participant?['last_name'] as String? ?? '';
    final name = '$fn $ln'.trim().isEmpty ? 'Unknown' : '$fn $ln'.trim();
    final role = participant?['role'] as String? ?? 'client';
    final lastMsg = conv['last_message'] as String? ?? 'Start the conversation';
    final lastAt = conv['last_message_at'] as String?;
    final timeStr = lastAt != null ? _formatTime(DateTime.parse(lastAt).toLocal()) : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border)),
        child: Row(children: [
          // Avatar
          Stack(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brand.withValues(alpha: 0.15),
                border: Border.all(color: _brand.withValues(alpha: 0.4), width: 1.5)),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: _brand, fontSize: 20, fontWeight: FontWeight.w800))),
            Positioned(bottom: 1, right: 1,
              child: Container(
                width: 13, height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _green,
                  border: Border.all(color: _card, width: 2)))),
          ]),
          const SizedBox(width: 12),
          // Content
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(name,
                    style: const TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w700))),
                Text(timeStr,
                  style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 11)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _brand.withValues(alpha: 0.25))),
                  child: Text(
                    role[0].toUpperCase() + role.substring(1),
                    style: const TextStyle(color: _primary, fontSize: 9, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 5),
              Text(lastMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _muted.withValues(alpha: 0.6), fontSize: 13)),
            ])),
        ])));
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message, sub;
  const _EmptyState({required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: _brand.withValues(alpha: 0.3), size: 52),
        const SizedBox(height: 16),
        Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _white, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(sub,
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 13)),
      ])));
}
