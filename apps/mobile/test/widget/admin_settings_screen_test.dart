import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:circle_fitness/features/admin/domain/admin_metrics.dart';
import 'package:circle_fitness/features/admin/domain/admin_provider.dart';
import 'package:circle_fitness/features/admin/presentation/admin_settings_screen.dart';

/// V5 §186 — P5 · Settings. The page keeps every published section even where nothing
/// backs it, per `BOUNDARIES F` (*"Designs kept. Approved design requirement;
/// implementation/architecture capability required"*), so the tests check that the design
/// was preserved AND that no field was invented to fill it.
Future<void> _pump(WidgetTester t, List<Override> o) async {
  await t.binding.setSurfaceSize(const Size(500, 6000));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(ProviderScope(
    overrides: o,
    child: const MaterialApp(home: AdminSettingsScreen()),
  ));
  await t.pump();
}

final _denied = <Override>[
  adminRoleCapabilitiesProvider.overrideWith((_) async => null),
  adminAdministratorCountProvider.overrideWith((_) async => null),
  adminPlatformSettingsProvider.overrideWith((_) async => null),
];

String _allText(WidgetTester t) =>
    t.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? '').join(' | ');

/// The approved matrix, shaped as `admin_role_capabilities` returns it.
List<AdminRoleCapability> _matrix() => [
      for (final r in ['trust_lead', 'operations_lead', 'support'])
        for (final a in ['Community', 'Events', 'Security'])
          AdminRoleCapability.fromRow({'admin_role': r, 'area': a, 'verb': 'view'}),
    ];

void main() {
  testWidgets('every published section is PRESENT, including the ones nothing backs — '
      'the design is kept rather than trimmed to fit the schema', (t) async {
    await _pump(t, _denied);
    final text = _allText(t);
    for (final s in ['ADMINISTRATORS', 'ROLES & PERMISSIONS', 'GENERAL', 'ORGANIZATION',
                     'NOTIFICATIONS', 'AI & INTELLIGENCE', 'DATA & PRIVACY',
                     'SECURITY SETTINGS', 'INTEGRATION SETTINGS',
                     'BILLING & MONETIZATION', 'STATE SYSTEM']) {
      expect(text.contains(s), isTrue, reason: 'missing section $s');
    }
  });

  testWidgets('each unbacked section states its OWN reason, not one vague apology',
      (t) async {
    await _pump(t, _denied);
    expect(find.textContaining('No organization record exists in the schema'),
        findsOneWidget);
    expect(find.textContaining('No notification configuration keys'), findsOneWidget);
    expect(find.textContaining('No billing configuration keys'), findsOneWidget);
    // Each distinct reason appears exactly once — a shared placeholder would repeat.
    expect(AdminSettingsScreen.unbackedSections.values.toSet().length,
        AdminSettingsScreen.unbackedSections.length,
        reason: 'every unbacked section must carry a distinct reason');
  });

  testWidgets('no organization FIELD is invented — the absence is stated, not filled',
      (t) async {
    await _pump(t, _denied);
    for (final invented in ['Organization name', 'Address', 'Legal entity', 'Tax ID',
                            'Logo']) {
      expect(find.text(invented), findsNothing,
          reason: 'no organization table exists, so "$invented" would be invented');
    }
  });

  testWidgets('no capability means every backed section says so', (t) async {
    await _pump(t, _denied);
    expect(find.text('Not available to your role'), findsWidgets);
  });

  group('#roles renders the approved policy, not a description of it', () {
    testWidgets('the grant total, the role count and the area count are all shown',
        (t) async {
      await _pump(t, [
        ..._denied,
        adminRoleCapabilitiesProvider.overrideWith((_) async => _matrix()),
      ]);
      expect(find.text('Granted capabilities'), findsOneWidget);
      expect(find.text('9'), findsWidgets);   // 3 roles x 3 areas
      expect(find.text('Roles'), findsOneWidget);
      expect(find.text('Areas'), findsOneWidget);
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('each role carries its own grant count, so a role losing grants is '
        'visible rather than hidden in a total', (t) async {
      await _pump(t, [
        ..._denied,
        adminRoleCapabilitiesProvider.overrideWith((_) async => [
              ..._matrix(),
              AdminRoleCapability.fromRow(
                  {'admin_role': 'viewer', 'area': 'Community', 'verb': 'view'}),
            ]),
      ]);
      expect(find.text('trust_lead'), findsOneWidget);
      expect(find.text('viewer'), findsOneWidget);
      expect(find.text('1'), findsWidgets); // viewer holds exactly one
    });

    testWidgets('a role name outside the known set is counted, not dropped', (t) async {
      final caps = [
        AdminRoleCapability.fromRow({'admin_role': null, 'area': 'X', 'verb': 'view'}),
      ];
      await _pump(t, [
        ..._denied,
        adminRoleCapabilitiesProvider.overrideWith((_) async => caps),
      ]);
      expect(find.text('unrecognised'), findsOneWidget);
    });

    testWidgets('it says it is the policy itself, so a disagreement with the validator '
        'is legible', (t) async {
      await _pump(t, [
        ..._denied,
        adminRoleCapabilitiesProvider.overrideWith((_) async => _matrix()),
      ]);
      expect(find.textContaining('approved authorization policy as seeded'),
          findsOneWidget);
    });
  });

  group('#platform shows stored values uninterpreted', () {
    testWidgets('a key/value pair is rendered as stored', (t) async {
      await _pump(t, [
        ..._denied,
        adminPlatformSettingsProvider.overrideWith((_) async => [
              AdminPlatformSetting.fromRow(const {
                'key': 'marketplace_commission_rate',
                'value': '0.10',
                'updated_at': '2026-08-24T07:38:03Z',
              }),
            ]),
      ]);
      expect(find.text('marketplace_commission_rate'), findsOneWidget);
      // AS STORED — not reformatted to "10%", which would assert a unit the generic
      // key/value table does not declare.
      expect(find.text('0.10'), findsOneWidget);
      expect(find.text('10%'), findsNothing);
      expect(find.textContaining('nothing here is parsed'), findsOneWidget);
    });

    testWidgets('an empty store is "Not recorded", distinct from no capability',
        (t) async {
      await _pump(t, [
        ..._denied,
        adminPlatformSettingsProvider
            .overrideWith((_) async => const <AdminPlatformSetting>[]),
      ]);
      expect(find.text('Not recorded'), findsWidgets);
    });
  });

  testWidgets('the page is READ-ONLY — settings writes would each need their own '
      'authorization review, and none is authorized here', (t) async {
    await _pump(t, _denied);
    expect(find.textContaining('Nothing is changed from this screen'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
  });
}
