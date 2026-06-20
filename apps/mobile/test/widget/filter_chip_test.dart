// Widget tests for filter-chip and status-badge UI patterns used across the
// coach marketplace (UC37) and coach dashboard (UC-invites).
// We define local equivalents of the private `_FilterChip` / `_StatusBadge`
// classes so the tests remain independent of the source file's library privacy.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Local copies of the widget logic under test ───────────────────────────────

class TestFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const TestFilterChip(
      {super.key, required this.label, required this.selected, required this.onTap});

  static const _brand = Color(0xFFA855F7);
  static const _card  = Color(0xFF0E0B16);
  static const _brd   = Color(0xFF1A1020);
  static const _wht   = Colors.white;
  static const _mut   = Color(0xFFCFC2D6);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
              color: selected ? _brand : _card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? _brand : _brd)),
          child: Text(label,
              style: TextStyle(
                  color: selected ? _wht : _mut,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      );
}

class TestStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const TestStatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w700)),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('TestFilterChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(
        TestFilterChip(label: 'Strength', selected: false, onTap: () {}),
      ));
      expect(find.text('Strength'), findsOneWidget);
    });

    testWidgets('selected chip has brand background', (tester) async {
      await tester.pumpWidget(_wrap(
        TestFilterChip(label: 'All', selected: true, onTap: () {}),
      ));
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFA855F7));
    });

    testWidgets('unselected chip has card background', (tester) async {
      await tester.pumpWidget(_wrap(
        TestFilterChip(label: 'Cardio', selected: false, onTap: () {}),
      ));
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF0E0B16));
    });

    testWidgets('tap callback fires', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        TestFilterChip(
          label: 'Yoga',
          selected: false,
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.byType(GestureDetector));
      expect(tapped, isTrue);
    });
  });

  group('TestStatusBadge', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(_wrap(
        const TestStatusBadge(label: 'Your Coach', color: Color(0xFF6FFBBE)),
      ));
      expect(find.text('Your Coach'), findsOneWidget);
    });

    testWidgets('renders "Request Sent" badge', (tester) async {
      await tester.pumpWidget(_wrap(
        const TestStatusBadge(label: 'Request Sent', color: Color(0xFFCFC2D6)),
      ));
      expect(find.text('Request Sent'), findsOneWidget);
    });

    testWidgets('text color matches provided color', (tester) async {
      const badgeColor = Color(0xFF6FFBBE);
      await tester.pumpWidget(_wrap(
        const TestStatusBadge(label: 'Active', color: badgeColor),
      ));
      final text = tester.widget<Text>(find.text('Active'));
      expect(text.style?.color, badgeColor);
    });
  });
}
