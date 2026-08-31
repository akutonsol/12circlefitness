// H-G* — Workstream H product-integrity / feature-contract guards.
//
// Same shape and intent as `error_contract_guard_test.dart` (Workstream B):
// STATIC guards that parse the committed source, so a regression fails
// `flutter test` without a database, credentials or a running app.
//
// They assert only what is already true of the tree today. Nothing here changes
// product behaviour and nothing here asserts a fix that has not been made — the
// open findings are recorded in
// `docs/QA_WORKSTREAM_H_PRODUCT_INTEGRITY_REPORT.md`, and the two register
// guards are deliberately written as *shrinking allowlists* so that closing a
// finding is a one-line deletion here rather than a test rewrite.
//
// What is guarded:
//   H-G1  no NEW phantom COLUMN: every column the Flutter client names against
//         a migration-defined table exists in `supabase/migrations`, except the
//         recorded, live-verified allowlist. (EC-G2 does this for tables; a
//         missing column is the same defect one level down, and PostgREST
//         answers it with the same 4xx nobody sees.)
//   H-G2  `messages.metadata` specifically — the chat photo path builds its row
//         through a variable, so H-G1's literal-map parser cannot see it.
//   H-G3  no NEW phantom STORAGE BUCKET: every bucket the client uploads to or
//         signs URLs from is created by a migration, except the recorded
//         allowlist.
//   H-G4  the client→coach display-name reads that migration 102 closed are
//         recorded, and the set does not grow.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ── Locating the tree ────────────────────────────────────────────────────────

Directory _mobileRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/pubspec.yaml').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not locate the Flutter package root');
    }
    dir = parent;
  }
  return dir;
}

Directory _repoRoot() {
  var dir = _mobileRoot();
  while (!Directory('${dir.path}/supabase/migrations').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not locate supabase/migrations');
    }
    dir = parent;
  }
  return dir;
}

String _read(String relativeToRepoRoot) =>
    File('${_repoRoot().path}/$relativeToRepoRoot').readAsStringSync();

Iterable<File> _filesUnder(String relativeDir, String extension) sync* {
  final dir = Directory('${_repoRoot().path}/$relativeDir');
  if (!dir.existsSync()) return;
  for (final e in dir.listSync(recursive: true)) {
    if (e is! File) continue;
    final p = e.path;
    if (p.contains('/node_modules/') || p.contains('/build/')) continue;
    if (!p.endsWith(extension)) continue;
    yield e;
  }
}

String _rel(File f) => f.path.split('/apps/mobile/').last;

// ── The migration sequence, as a column map ──────────────────────────────────

/// SQL with `--` line comments removed. Written character-wise rather than with
/// a regex because an inline `-- 1..5` after a column definition otherwise
/// swallows the *next* column into the comment and reports it as missing.
String _stripSqlComments(String sql) {
  final out = StringBuffer();
  for (final line in sql.split('\n')) {
    var inQuote = false;
    for (var i = 0; i < line.length; i++) {
      if (line[i] == "'") inQuote = !inQuote;
      if (!inQuote && i + 1 < line.length && line[i] == '-' && line[i + 1] == '-') {
        break;
      }
      out.write(line[i]);
    }
    out.writeln();
  }
  return out.toString();
}

/// Splits a `CREATE TABLE` body on commas that are not inside brackets.
List<String> _topLevelParts(String body) {
  final parts = <String>[];
  final cur = StringBuffer();
  var depth = 0;
  for (final ch in body.split('')) {
    if (ch == '(' || ch == '[') depth++;
    if (ch == ')' || ch == ']') depth--;
    if (ch == ',' && depth == 0) {
      parts.add(cur.toString());
      cur.clear();
    } else {
      cur.write(ch);
    }
  }
  parts.add(cur.toString());
  return parts;
}

const _constraintKeywords = {
  'primary', 'foreign', 'unique', 'check', 'constraint', 'exclude', 'like',
};

class _Schema {
  final Map<String, Set<String>> columns;
  final Set<String> views;
  _Schema(this.columns, this.views);

  Set<String> get tables => columns.keys.toSet();
}

_Schema _parseMigrations() {
  final columns = <String, Set<String>>{};
  final views = <String>{};

  void add(String table, String column) {
    final t = table.toLowerCase().replaceAll('"', '').trim();
    final c = column.toLowerCase().replaceAll('"', '').trim();
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(c)) return;
    columns.putIfAbsent(t, () => <String>{}).add(c);
  }

  final files = _filesUnder('supabase/migrations', '.sql').toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final f in files) {
    final sql = _stripSqlComments(f.readAsStringSync());

    for (final m in RegExp(
      r'create\s+table\s+(?:if\s+not\s+exists\s+)?(?:public\.)?("?[a-zA-Z0-9_]+"?)\s*\(([\s\S]*?)\n\s*\)\s*;',
      caseSensitive: false,
    ).allMatches(sql)) {
      for (final part in _topLevelParts(m.group(2)!)) {
        final p = part.trim();
        if (p.isEmpty) continue;
        final first = p.split(RegExp(r'\s+')).first;
        if (_constraintKeywords.contains(first.toLowerCase())) continue;
        add(m.group(1)!, first);
      }
    }

    for (final m in RegExp(
      r'alter\s+table\s+(?:only\s+)?(?:if\s+exists\s+)?(?:public\.)?("?[a-zA-Z0-9_]+"?)\s+([\s\S]*?);',
      caseSensitive: false,
    ).allMatches(sql)) {
      final body = m.group(2)!;
      for (final mm in RegExp(
        r'add\s+column\s+(?:if\s+not\s+exists\s+)?("?[a-zA-Z0-9_]+"?)',
        caseSensitive: false,
      ).allMatches(body)) {
        add(m.group(1)!, mm.group(1)!);
      }
      for (final mm in RegExp(
        r'rename\s+column\s+"?[a-zA-Z0-9_]+"?\s+to\s+("?[a-zA-Z0-9_]+"?)',
        caseSensitive: false,
      ).allMatches(body)) {
        add(m.group(1)!, mm.group(1)!);
      }
    }

    for (final m in RegExp(
      r'create\s+(?:or\s+replace\s+)?(?:materialized\s+)?view\s+(?:public\.)?("?[a-zA-Z0-9_]+"?)',
      caseSensitive: false,
    ).allMatches(sql)) {
      views.add(m.group(1)!.toLowerCase().replaceAll('"', ''));
    }
  }

  return _Schema(columns, views);
}

// ── What the client names ────────────────────────────────────────────────────

/// Column tokens from a PostgREST `select()` string.
///
/// Everything inside parentheses is an *embedded resource*'s own column list —
/// `public_profiles!user_id(id, first_name)` — and belongs to that table, not
/// this one, so the bracketed spans are dropped whole. What survives is then
/// filtered to bare identifiers, which also removes the `table!fk` and
/// `alias:column` embed heads.
List<String> _selectColumns(String raw) {
  final flat = StringBuffer();
  var depth = 0;
  for (final ch in raw.split('')) {
    if (ch == '(') {
      depth++;
      continue;
    }
    if (ch == ')') {
      depth--;
      continue;
    }
    if (depth == 0) flat.write(ch);
  }
  return flat
      .toString()
      .split(RegExp(r'[,\s]+'))
      .map((t) => t.trim())
      .where((t) => RegExp(r'^[a-z0-9_]+$').hasMatch(t))
      .toList();
}

/// Top-level keys of the map literal passed to `insert` / `update` / `upsert`.
///
/// Depth matters: `'data': {'client_id': …}` writes the column `data`, not a
/// column `client_id`, and `'status': x ? 'attended' : 'y'` writes no column
/// called `attended`. Only keys at brace depth 0 of the payload count.
List<String> _payloadKeys(String segment) {
  final keys = <String>[];
  for (final m in RegExp(r"\.(insert|update|upsert)\(\s*\{").allMatches(segment)) {
    final buf = StringBuffer();
    var depth = 0;
    var i = m.end;
    while (i < segment.length) {
      final ch = segment[i];
      if (ch == '{' || ch == '[' || ch == '(') {
        depth++;
      } else if (ch == '}' || ch == ']' || ch == ')') {
        if (depth == 0) break;
        depth--;
      }
      if (depth == 0) buf.write(ch);
      i++;
    }
    for (final km
        in RegExp(r"(^|[{,])\s*'([a-z0-9_]+)'\s*:").allMatches(buf.toString())) {
      keys.add(km.group(2)!);
    }
  }
  return keys;
}

const _filterMethods =
    r'eq|neq|gt|gte|lt|lte|like|ilike|is_|in_|inFilter|contains|order|filter';

/// table.column -> the call sites that name it.
Map<String, Set<String>> _clientColumnReferences(_Schema schema) {
  final refs = <String, Set<String>>{};

  for (final f in _filesUnder('apps/mobile/lib', '.dart')) {
    final src = f.readAsStringSync();
    for (final m in RegExp(r"\.from\(\s*'([a-z0-9_]+)'\s*\)").allMatches(src)) {
      final table = m.group(1)!;
      // `client.storage.from('bucket')` names a bucket, not a table.
      final before = src.substring(0, m.start).replaceAll(RegExp(r'\s+'), '');
      if (before.endsWith('.storage')) continue;
      // Tables with no CREATE at all are EC-G2's business, and a view's column
      // list is not reconstructable from the migrations by this parser.
      if (!schema.columns.containsKey(table)) continue;
      if (schema.views.contains(table)) continue;

      var seg = src.substring(m.end, (m.end + 2000).clamp(0, src.length));
      final end = seg.indexOf(';');
      if (end != -1) seg = seg.substring(0, end);

      final used = <String>[];
      for (final sm in RegExp(r"\.select\(\s*'''([\s\S]*?)'''|\.select\(\s*'([\s\S]*?)'")
          .allMatches(seg)) {
        used.addAll(_selectColumns(sm.group(1) ?? sm.group(2) ?? ''));
      }
      used.addAll(_payloadKeys(seg));
      for (final sm
          in RegExp("\\.($_filterMethods)\\(\\s*'([a-z0-9_]+)'").allMatches(seg)) {
        used.add(sm.group(2)!);
      }

      final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
      for (final c in used) {
        if (schema.columns[table]!.contains(c)) continue;
        // A bare table name in a select list is an embedded resource
        // (`event_registrations(count)`), and `count` is the aggregate itself.
        if (schema.tables.contains(c) || schema.views.contains(c) || c == 'count') {
          continue;
        }
        refs.putIfAbsent('$table.$c', () => <String>{}).add('${_rel(f)}:$line');
      }
    }
  }
  return refs;
}

void main() {
  late final _Schema schema = _parseMigrations();

  // ── H-G1 · no new phantom columns ─────────────────────────────────────────
  //
  // The three entries below were confirmed against QA read-only on 2026-08-24.
  // PostgREST resolves the column list before it checks the table grant, so
  // `?select=<col>` is an existence oracle: 42703 means the column is absent,
  // 42501 means it is present and only the grant refused. All three answered
  // 42703. Every caller swallows the 400 and reports an empty or successful
  // result, which is why none of them has ever surfaced as a bug.
  //
  // Remove an entry when the column is added or its caller is corrected.
  group('H-G1 every column the client names has a backing migration', () {
    const knownMissing = <String, String>{
      // Event registration writes and reads `ticket_code`; the column is
      // `qr_code`. The ticket screen catches the 400 and fabricates a
      // "TKT-DEMO-…" ticket that was never persisted.
      'event_registrations.ticket_code': 'H-02',
      // Admin approval of a submitted exercise writes `approved_by`; only
      // `approved_at` exists. Approve always fails; reject always works.
      'custom_exercises.approved_by': 'H-03',
    };

    test('the migration parser found a plausible schema', () {
      // A guard that silently parses nothing would pass forever.
      expect(schema.columns.length, greaterThan(80));
      expect(schema.columns['user_profiles'], contains('onboarding_complete'));
      expect(schema.columns['workout_set_logs'], contains('logged_at'));
      expect(schema.columns['cycle_symptoms'], contains('flow'));
    });

    test('no phantom column outside the recorded allowlist', () {
      final refs = _clientColumnReferences(schema);
      final unexpected = {
        for (final e in refs.entries)
          if (!knownMissing.containsKey(e.key)) e.key: e.value,
      };
      expect(unexpected, isEmpty,
          reason: 'A column the client names but no migration creates is a 400 '
              'that every caller in this codebase swallows into an empty or '
              'success-shaped answer. Add the column, or fix the caller.');
    });

    test('each recorded phantom column is still referenced and still missing',
        () {
      final refs = _clientColumnReferences(schema);
      for (final entry in knownMissing.entries) {
        expect(refs.keys, contains(entry.key),
            reason: '${entry.value}: if this call site is gone, delete the '
                'allowlist entry with it.');
      }
    });
  });

  // ── H-G2 · messages.metadata ──────────────────────────────────────────────
  //
  // H-G1 cannot see this one: `sendMessage` assembles a `row` variable and only
  // then does `row['metadata'] = metadata`, so there is no literal map key to
  // parse. Pinned explicitly because the consequence is silent — the photo is
  // uploaded, the message insert 400s, `sendMessage` returns false, and
  // `_sendPhoto` never checks the return value, so nothing is shown to anyone.
  group('H-G2 the chat photo path still names a column that does not exist',
      () {
    test('messaging_service sets a `metadata` key that messages has no column for',
        () {
      final service =
          _read('apps/mobile/lib/features/messaging/data/messaging_service.dart');
      expect(service, contains("row['metadata'] = metadata"));
      expect(schema.columns['messages'], isNotNull);
      expect(schema.columns['messages'], isNot(contains('metadata')),
          reason: 'H-04: if the column has been added, delete this guard.');
    });

    test('_sendPhoto does not check sendMessage\'s boolean result', () {
      final chat =
          _read('apps/mobile/lib/features/messaging/presentation/chat_screen.dart');
      final i = chat.indexOf('Future<void> _sendPhoto');
      expect(i, greaterThan(-1));
      final body = chat.substring(i).split('\n').take(35).join('\n');
      expect(body, contains('_service.sendMessage('));
      expect(body.contains('final ok = await _service.sendMessage'), isFalse,
          reason: 'H-04: when the return value is checked, update this guard '
              'and the report entry together.');
    });
  });

  // ── H-G3 · no new phantom storage buckets ─────────────────────────────────
  //
  // Confirmed against QA read-only: `GET /storage/v1/object/public/<bucket>/x`
  // answers `NoSuchKey` for a bucket that exists and `NoSuchBucket` for one that
  // does not. `avatars`, `coach-media` and `exercise-media` answered NoSuchKey;
  // the two below answered NoSuchBucket.
  group('H-G3 every storage bucket the client uses is created by a migration',
      () {
    // progress-photos: migration 029 writes storage.objects RLS *for* this
    //   bucket but nothing ever creates it (H-05).
    // chat-media: created nowhere at all (H-04).
    const knownMissing = {'progress-photos', 'chat-media'};

    test('no phantom bucket outside the recorded allowlist', () {
      final used = <String, Set<String>>{};
      for (final f in _filesUnder('apps/mobile/lib', '.dart')) {
        final src = f.readAsStringSync();
        for (final m in RegExp(r"storage\s*\.from\(\s*'([a-z0-9_-]+)'\s*\)")
            .allMatches(src)) {
          final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
          used
              .putIfAbsent(m.group(1)!, () => <String>{})
              .add('${_rel(f)}:$line');
        }
      }
      expect(used, isNotEmpty, reason: 'the bucket scanner matched nothing');

      final sql = StringBuffer();
      for (final f in _filesUnder('supabase/migrations', '.sql')) {
        sql.writeln(f.readAsStringSync().toLowerCase());
      }
      final created = RegExp(
        r"into\s+storage\.buckets[\s\S]{0,200}?values\s*\(\s*'([a-z0-9_-]+)'",
      ).allMatches(sql.toString()).map((m) => m.group(1)!).toSet();
      expect(created, contains('avatars'));

      final missing = {
        for (final e in used.entries)
          if (!created.contains(e.key)) e.key: e.value,
      };
      expect(missing.keys.toSet(), knownMissing,
          reason: 'A bucket no migration creates cannot be rebuilt in a fresh '
              'environment, and every upload to it fails. Create it in a '
              'migration, or retire the caller.');
    });
  });

  // ── H-G4 · the client→coach profile reads migration 102 closed ────────────
  //
  // 102's SELECT policy on user_profiles is
  //   id = auth.uid() OR is_active_coach_of(id) OR is_team_lead_of(id)
  //                   OR hosts_event_for(id)
  // — the coach may read their ACTIVE client; the client may never read the
  // coach, and a coach may not read a PENDING requester. Verified live on QA:
  // signed in as the seeded client, whose relationship to the seeded coach is
  // `active`, `user_profiles?id=eq.<coach>` returns `[]`.
  //
  // The migration's own header lists the surfaces it expected to move to
  // `public_profiles` / `conversation_participant_profiles`. These four were
  // not moved. Recorded as a shrinking allowlist.
  group('H-G4 the coach-facing profile reads still go to the base table', () {
    const sites = <String, String>{
      'apps/mobile/lib/features/coach/data/coach_relationship_service.dart':
          'getPendingRequests / getMyActiveCoaches',
    };

    test('102 is the policy this guard is about', () {
      final sql = _read('supabase/migrations/102_restrict_user_profiles.sql');
      expect(sql, contains('own profile or active coach reads profile'));
      expect(sql, contains('public.is_active_coach_of(id)'));
    });

    test('the recorded sites still read user_profiles, not a display view', () {
      for (final entry in sites.entries) {
        final src = _read(entry.key);
        expect(src, contains("from('user_profiles')"),
            reason: '${entry.value}: when this moves to public_profiles, '
                'delete the entry — H-06 is closed for that surface.');
      }
    });

    test('no NEW client-side surface starts reading a coach profile', () {
      // Files that read user_profiles for someone who is not the signed-in user
      // and not an active client of the signed-in coach. Growth here means a
      // new dead read shipped.
      final readers = <String>{};
      for (final f in _filesUnder('apps/mobile/lib/features/coach', '.dart')) {
        if (f.readAsStringSync().contains("from('user_profiles')")) {
          readers.add(_rel(f));
        }
      }
      expect(readers, {
        'lib/features/coach/data/coach_relationship_service.dart',
        'lib/features/coach/data/package_service.dart',
        'lib/features/coach/data/score_service.dart',
        'lib/features/coach/domain/coach_ecosystem_provider.dart',
        'lib/features/coach/presentation/coach_business_screen.dart',
        'lib/features/coach/presentation/coach_copilot_screen.dart',
        'lib/features/coach/presentation/coach_pricing_sheet.dart',
      });
    });
  });
}
