import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/app_scaffold.dart';
import 'event_ticket_screen.dart';

// ── Colors ────────────────────────────────────────────────────────────────────
class _C {
  static const card      = Color(0xFF131B2E);
  static const cardHigh  = Color(0xFF222A3D);
  static const primary   = Color(0xFFDDB7FF);
  static const brand     = Color(0xFFA855F7);
  static const onSurface = Color(0xFFDAE2FD);
  static const onSurfVar = Color(0xFFCFC2D6);
  static const teal      = Color(0xFF6FFBBE);
  static const amber     = Color(0xFFFFD580);
}

// ── Provider ──────────────────────────────────────────────────────────────────
final _eventsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final now = DateTime.now().toIso8601String();
  try {
    final data = await Supabase.instance.client
        .from('events')
        .select()
        .eq('status', 'upcoming')
        .gte('event_date', now)
        .order('event_date')
        .limit(30);
    return List<Map<String, dynamic>>.from(data as List);
  } catch (_) {
    return [];
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(_eventsProvider);

    return AppScaffold(
      navIndex: 2,
      showBackButton: true,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Events',
              style: TextStyle(color: _C.onSurface, fontSize: 28,
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('Community events, workshops and meetups',
              style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.6), fontSize: 13)),
          ])),

        // ── List ──
        Expanded(
          child: eventsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: _C.brand, strokeWidth: 2)),
            error: (_, __) => Center(
              child: Text('Could not load events',
                style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.5)))),
            data: (events) {
              if (events.isEmpty) return _EmptyState();
              return RefreshIndicator(
                color: _C.brand,
                backgroundColor: _C.card,
                onRefresh: () async => ref.invalidate(_eventsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _EventCard(
                    event: events[i],
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => EventTicketScreen(event: events[i]),
                    )))));
            })),
      ]),
    );
  }
}

// ── Event Card ────────────────────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title       = event['title'] as String? ?? 'Event';
    final description = event['description'] as String?;
    final location    = event['location'] as String?;
    final host        = event['host_name'] as String?;
    final eventDateRaw = event['event_date'] as String?;
    final maxCap      = event['max_capacity'] as int?;
    final registered  = event['current_registered'] as int? ?? 0;
    final isFree      = event['is_free'] as bool? ?? true;
    final price       = event['price'];
    final coverUrl    = event['cover_image_url'] as String?;

    final dateStr = eventDateRaw != null
        ? _fmtDateTime(DateTime.parse(eventDateRaw).toLocal())
        : '';
    final spotsLeft = maxCap != null ? maxCap - registered : null;
    final isFull = spotsLeft != null && spotsLeft <= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x1A6FFBBE))),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cover image or gradient header
          SizedBox(
            height: 100,
            child: Stack(fit: StackFit.expand, children: [
              coverUrl != null
                  ? Image.network(coverUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gradientHeader())
                  : _gradientHeader(),
              const DecoratedBox(decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xCC131B2E)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter))),
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFree
                        ? _C.teal.withValues(alpha: 0.15)
                        : _C.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isFree
                          ? _C.teal.withValues(alpha: 0.4)
                          : _C.amber.withValues(alpha: 0.4))),
                  child: Text(
                    isFree ? 'FREE' : '\$${price ?? ''}',
                    style: TextStyle(
                      color: isFree ? _C.teal : _C.amber,
                      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)))),
            ])),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                style: const TextStyle(color: _C.onSurface, fontSize: 16,
                  fontWeight: FontWeight.w700)),
              if (host != null) ...[
                const SizedBox(height: 4),
                Text('Hosted by $host',
                  style: TextStyle(color: _C.teal.withValues(alpha: 0.8), fontSize: 12)),
              ],
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(description,
                  style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.65),
                    fontSize: 13, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 6, children: [
                if (dateStr.isNotEmpty) _chip(Icons.event_rounded, dateStr, _C.primary),
                if (location != null) _chip(Icons.location_on_outlined, location, _C.onSurfVar),
                if (spotsLeft != null)
                  _chip(
                    Icons.people_outline_rounded,
                    isFull ? 'Full' : '$spotsLeft spots left',
                    isFull ? Colors.redAccent : _C.teal),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: isFull ? null : const LinearGradient(
                      colors: [Color(0xFF00A572), Color(0xFF6FFBBE)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight),
                    color: isFull ? _C.cardHigh : null,
                    borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text(
                      isFull ? 'Event Full' : 'View & Register',
                      style: TextStyle(
                        color: isFull ? _C.onSurfVar : Colors.black87,
                        fontSize: 13, fontWeight: FontWeight.w700))))),
            ])),
        ])));
  }

  Widget _gradientHeader() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0B2E1A), Color(0xFF0B1326)],
        begin: Alignment.topLeft, end: Alignment.bottomRight)));

  Widget _chip(IconData icon, String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color.withValues(alpha: 0.7), size: 13),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12)),
    ]);

  String _fmtDateTime(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '${months[d.month - 1]} ${d.day} • $h:$m $ampm';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.event_rounded, color: _C.teal.withValues(alpha: 0.25), size: 56),
      const SizedBox(height: 16),
      const Text('No upcoming events',
        style: TextStyle(color: _C.onSurface, fontSize: 17,
          fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('Check back soon for community events',
        style: TextStyle(color: _C.onSurfVar.withValues(alpha: 0.5), fontSize: 13)),
    ]));
}
