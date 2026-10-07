import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// V5 §163 · SEC-G4 — a ratchet on the Admin metric null semantics.
///
/// The behavioural tests in `admin_metric_semantics_test.dart` prove the models
/// preserve null today. This guard exists because the defect they protect against
/// is a ONE-CHARACTER EDIT away at all times: adding `?? 0` to a getter, or
/// changing an `int?` field to `int`, would make every one of those tests still
/// compile and most of them still pass, while silently converting "you are not
/// authorized to see this" into "the answer is zero".
///
/// For METRIC-02 that is an indirect statement about the Security-owned audit
/// population a `Users`-only role may not query. For METRIC-06 it fabricates a
/// monetary figure the owner's calculation explicitly forbids. For METRIC-14 it
/// turns "nobody registered" into "nobody turned up".
void main() {
  // Resolve relative to this file so the guard works from any working directory.
  const root = 'lib/features/admin';
  final files = <String, String>{
    'models': '$root/domain/admin_metrics.dart',
    'service': '$root/data/admin_metrics_service.dart',
    'providers': '$root/domain/admin_provider.dart',
  };

  late Map<String, String> sources;

  setUpAll(() {
    sources = {
      for (final e in files.entries) e.key: File(e.value).readAsStringSync(),
    };
    // POSITIVE CONTROL. A guard that reads an empty string reports every file
    // clean, which is how three checkers in this programme have already reported
    // success from nothing (V5 §139.3). Prove the scan can see text it must see.
    for (final e in sources.entries) {
      if (e.value.trim().isEmpty) {
        fail('SEC-G4: ${files[e.key]} read as EMPTY — the scan is broken, not the '
            'code; refusing to report a clean result over nothing');
      }
    }
    if (!sources['models']!.contains('class AdminActivityOverview')) {
      fail('SEC-G4: could not find AdminActivityOverview in the models file, '
          'which it definitely contains — the scan is broken');
    }
  });

  test('no file in the Admin metric layer defaults a metric to zero', () {
    final offenders = <String>[];
    for (final e in sources.entries) {
      final lines = e.value.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Comments discuss `?? 0` at length on purpose; only code counts.
        final code = line.split('//').first;
        if (RegExp(r'\?\?\s*0(\.0)?\b').hasMatch(code)) {
          offenders.add('${files[e.key]}:${i + 1}: ${line.trim()}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'a null here means "unauthorized" or "not recorded", never zero.\n'
            '${offenders.join('\n')}');
  });

  test('every numeric field on every metric model stays nullable', () {
    // A non-nullable `int count;` forces a default at construction, and the only
    // available default is a lie.
    final bad = <String>[];
    final lines = sources['models']!.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final code = lines[i].split('//').first.trim();
      final m = RegExp(r'^final\s+(int|double|num)\s+(\w+)\s*;').firstMatch(code);
      if (m != null) bad.add('admin_metrics.dart:${i + 1}: ${m.group(0)}');
    }
    expect(bad, isEmpty,
        reason: 'these fields cannot represent "unavailable":\n${bad.join('\n')}');
  });

  test('the service returns nullable models, so a missing row stays missing', () {
    // `maybeSingle()` yields null for no row; `single()` throws, and a caught
    // throw would most likely be turned into an empty model full of zeros.
    final service = sources['service']!;
    expect(service.contains('maybeSingle()'), isTrue,
        reason: 'the view read must tolerate "no row" as a first-class outcome');
    expect(RegExp(r'\.single\(\)').hasMatch(service), isFalse,
        reason: 'single() throws on the unauthorized case, which invites a catch '
            'block that invents a zeroed model');
    for (final m in RegExp(r'Future<(\w+)\??>\s+get\w+\(').allMatches(service)) {
      expect(m.group(0), contains('?>'),
          reason: '${m.group(1)} must be returned nullable: ${m.group(0)}');
    }
  });

  test('no provider substitutes an empty model when a surface returns no row', () {
    final providers = sources['providers']!;
    for (final m in RegExp(r'FutureProvider<(Admin\w+)(\??)>').allMatches(providers)) {
      expect(m.group(2), '?',
          reason: '${m.group(1)} provider must be nullable so the UI can render '
              'the approved A11 state instead of a zeroed card');
    }
    // A constructor call inside the providers block would be that substitution.
    final block = providers.substring(providers.indexOf('V5 §163'));
    expect(RegExp(r'const\s+Admin\w+Overview\(').hasMatch(block), isFalse,
        reason: 'a provider must not construct a stand-in model');
  });

  test('METRIC-11 exposes no combined verdict, in Dart as in SQL', () {
    // The owner ruled the CI verdict and the gate verdict "must not be collapsed".
    // Comments NAME these forbidden getters in order to explain why they are absent,
    // so the scan must read code only — the first draft of this guard matched its
    // own documentation and failed, which is a scan defect, not a code defect.
    final models = sources['models']!
        .split('\n')
        .map((l) => l.split('//').first)
        .join('\n');
    final combined = RegExp(
            r'\b(get\s+)?(isReleasable|overallStatus|combinedVerdict|isBlocked|releaseBadge)\b')
        .allMatches(models)
        .map((m) => m.group(0)!)
        .toList();
    // Prove the pattern can still fire, so "no matches" means "none present"
    // rather than "the regex is broken".
    expect(
        RegExp(r'\b(get\s+)?(isReleasable|overallStatus|combinedVerdict|isBlocked|releaseBadge)\b')
            .hasMatch('bool get isReleasable => true;'),
        isTrue,
        reason: 'the forbidden-getter pattern must match a known offender');
    expect(combined, isEmpty,
        reason: 'a convenience getter here would assert a release verdict neither '
            'CI nor the gate ledger gave: ${combined.join(', ')}');
  });
}
