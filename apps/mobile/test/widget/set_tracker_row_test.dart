// WKT-110 — the Workout Zone set row renders a completed set as a record.
//
// The state layer already refuses edits to a completed set
// (test/unit/workout_set_immutability_test.dart); these tests cover the other
// half of the fix: the row must not *look* editable when it isn't, and its
// completion check must not be a toggle.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:circle_fitness/features/workout/presentation/widgets/set_tracker_row.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Material(child: child)),
    );

void main() {
  // The row runs a looping "notes" pulse animation, so tests pump frames
  // explicitly rather than settling (which would never finish).
  group('WKT-110 an incomplete set offers editable fields', () {
    testWidgets('weight, reps and RPE are text inputs', (tester) async {
      await tester.pumpWidget(_host(SetTrackerRow(
        setNumber: 1,
        targetReps: 10,
        targetWeight: 60,
        completed: false,
        onCompleted: (_, __, ___, ____) {},
      )));
      await tester.pump();

      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('tapping the check reports the entered values', (tester) async {
      int? reps;
      double? weightKg;
      await tester.pumpWidget(_host(SetTrackerRow(
        setNumber: 1,
        targetReps: 10,
        targetWeight: 60,
        completed: false,
        unit: 'kg',
        onCompleted: (r, w, _, __) {
          reps = r;
          weightKg = w;
        },
      )));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), '90');
      await tester.enterText(find.byType(TextField).at(1), '8');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(reps, 8);
      expect(weightKg, 90);
    });
  });

  group('WKT-110 a completed set is shown, not offered for editing', () {
    testWidgets('weight, reps and RPE are read-only values', (tester) async {
      await tester.pumpWidget(_host(SetTrackerRow(
        setNumber: 1,
        targetReps: 10,
        targetWeight: 60,
        completed: true,
        unit: 'lb',
        savedWeightKg: 90.718474, // 200 lb
        savedReps: 10,
        savedRpe: 5,
        onCompleted: (_, __, ___, ____) {},
      )));
      await tester.pump();

      expect(find.byType(TextField), findsNothing,
          reason: 'a recorded set must not present editable inputs');
      expect(find.text('200'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('tapping the check cannot deselect it', (tester) async {
      var completions = 0;
      await tester.pumpWidget(_host(SetTrackerRow(
        setNumber: 1,
        targetReps: 10,
        targetWeight: 60,
        completed: true,
        savedWeightKg: 90,
        savedReps: 10,
        onCompleted: (_, __, ___, ____) => completions++,
      )));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(completions, 0,
          reason: 'completion is one-way; the check is not a toggle');
    });

    testWidgets('the Edit affordance is the only way in, and is opt-in',
        (tester) async {
      var edits = 0;
      await tester.pumpWidget(_host(SetTrackerRow(
        setNumber: 1,
        targetReps: 10,
        targetWeight: 60,
        completed: true,
        savedWeightKg: 90,
        savedReps: 10,
        onCompleted: (_, __, ___, ____) {},
        onEditCompleted: () => edits++,
      )));
      await tester.pump();

      expect(find.text('Edit'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      await tester.pump();

      expect(edits, 1);
      expect(find.byType(TextField), findsNothing,
          reason: 'Edit opens the correction flow; it does not unlock the row');
    });

    testWidgets('no Edit action is shown when correction is unavailable',
        (tester) async {
      await tester.pumpWidget(_host(SetTrackerRow(
        setNumber: 1,
        targetReps: 10,
        targetWeight: 60,
        completed: true,
        savedWeightKg: 90,
        savedReps: 10,
        onCompleted: (_, __, ___, ____) {},
      )));
      await tester.pump();

      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('a note stays editable and re-emits the recorded numbers',
        (tester) async {
      int? reps;
      double? weightKg;
      String? notes;
      await tester.pumpWidget(_host(SetTrackerRow(
        setNumber: 1,
        targetReps: 10,
        targetWeight: 60,
        completed: true,
        unit: 'kg',
        savedWeightKg: 90,
        savedReps: 10,
        savedNotes: 'solid',
        onCompleted: (_, __, ___, ____) {},
        onChanged: (r, w, _, n) {
          reps = r;
          weightKg = w;
          notes = n;
        },
      )));
      await tester.pump();

      // The note field is the one input a completed row still shows.
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'felt heavier');
      await tester.pump(const Duration(milliseconds: 700)); // debounce

      expect(notes, 'felt heavier');
      expect(reps, 10, reason: 'the recorded reps travel back unchanged');
      expect(weightKg, 90, reason: 'the recorded weight travels back unchanged');
    });
  });
}
