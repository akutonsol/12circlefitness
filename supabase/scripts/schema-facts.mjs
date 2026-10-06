#!/usr/bin/env node
// Reads schema facts out of the migration set, and FAILS LOUDLY when it finds
// nothing rather than reporting a clean result.
//
// WHY THIS EXISTS. V5 §129.3 and §139.3: three ad-hoc checkers in this programme
// found nothing and announced success.
//   · a BSD-sed extractor printed "user_integrations  clean" for a table holding
//     access_token and refresh_token — `sed` does not support \? or \b, so the
//     table body never matched and the empty result was printed as a verdict;
//   · an RLS scan reported three tables as having no ENABLE ROW LEVEL SECURITY
//     because its regex assumed single spaces; all sixteen had it;
//   · a python extractor silently skipped workout_logs, because the baseline
//     migration QUOTES its identifiers ("workout_logs") and the pattern did not.
//
// All three were the same bug: a zero result treated as an answer. So every
// lookup here THROWS when the object is not found, quoted identifiers are handled,
// and `--self-test` proves the scanner can still see things it must see.
//
//   node supabase/scripts/schema-facts.mjs --self-test
//   node supabase/scripts/schema-facts.mjs columns user_integrations
import { readdirSync, readFileSync } from 'node:fs';

const DIR = 'supabase/migrations';

export function migrations() {
  const files = readdirSync(DIR).filter((f) => f.endsWith('.sql')).sort();
  if (files.length < 100) {
    throw new Error(`schema-facts: found only ${files.length} migration(s) in ${DIR} — ` +
      'refusing to answer from a set this small, because "not found" would then be meaningless');
  }
  return files.map((name) => ({ name, sql: readFileSync(`${DIR}/${name}`, 'utf8') }));
}

// `"name"` and `name` are the same object. The baseline migration quotes every
// identifier, which is exactly how workout_logs went missing from an audit.
const ident = (t) => `"?${t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}"?`;

/** Every column of `table`, from CREATE TABLE plus any later ADD COLUMN. Throws if the table is never declared. */
export function columnsOf(table, mig = migrations()) {
  const out = [];
  let declared = false;
  const create = new RegExp(
    `CREATE\\s+TABLE\\s+(?:IF\\s+NOT\\s+EXISTS\\s+)?(?:"?public"?\\.)?${ident(table)}\\s*\\(([\\s\\S]*?)\\n\\s*\\)\\s*;`, 'i');
  const add = new RegExp(
    `ALTER\\s+TABLE\\s+(?:IF\\s+EXISTS\\s+)?(?:"?public"?\\.)?${ident(table)}\\s+ADD\\s+COLUMN\\s+(?:IF\\s+NOT\\s+EXISTS\\s+)?"?([a-zA-Z_][a-zA-Z0-9_]*)"?\\s+([^;]+);`, 'gi');

  for (const m of mig) {
    const c = m.sql.match(create);
    if (c) {
      declared = true;
      for (let line of c[1].split('\n')) {
        line = line.trim().replace(/,$/, '');
        if (!line || line.startsWith('--')) continue;
        if (/^(PRIMARY|UNIQUE|FOREIGN|CONSTRAINT|CHECK|EXCLUDE)\b/i.test(line)) continue;
        const col = line.match(/^"?([a-zA-Z_][a-zA-Z0-9_]*)"?\s+(.+)/);
        if (col) out.push({ name: col[1], type: col[2], source: m.name });
      }
    }
    for (const a of m.sql.matchAll(add)) {
      declared = true;
      out.push({ name: a[1], type: a[2].trim(), source: `${m.name} (ALTER)` });
    }
  }
  if (!declared) {
    throw new Error(`schema-facts: table "${table}" is declared in NO migration. ` +
      'This is an error, not an empty answer — check the name before concluding anything about it.');
  }
  return out;
}

const SECRETISH = /token|secret|password|passwd|credential|cvv|iban|ssn|api_key|private_key/i;
/** Columns of `table` whose names suggest a credential. Throws if the table is unknown. */
export function secretColumnsOf(table, mig = migrations()) {
  return columnsOf(table, mig).filter((c) => SECRETISH.test(c.name)).map((c) => c.name);
}

/** True if any migration enables RLS on `table`. Throws if the table is unknown. */
export function rlsEnabled(table, mig = migrations()) {
  columnsOf(table, mig);                       // asserts the table exists first
  const re = new RegExp(`ALTER\\s+TABLE\\s+(?:"?public"?\\.)?${ident(table)}\\s+ENABLE\\s+ROW\\s+LEVEL\\s+SECURITY`, 'i');
  return mig.some((m) => re.test(m.sql));
}

// ── self-test ───────────────────────────────────────────────────────────────
if (process.argv[2] === '--self-test') {
  const mig = migrations();
  const fails = [];
  const t = (name, pass, detail = '') => {
    console.log(`  ${pass ? 'ok  ' : 'FAIL'}  ${name}${detail ? `  — ${detail}` : ''}`);
    if (!pass) fails.push(name);
  };

  // Each case is one of the three historical misses, turned into a standing test.
  const ui = columnsOf('user_integrations', mig).map((c) => c.name);
  t('user_integrations exposes its token columns (the §129.3 miss)',
    ui.includes('access_token') && ui.includes('refresh_token'), ui.join(','));
  t('secretColumnsOf flags exactly those two',
    JSON.stringify(secretColumnsOf('user_integrations', mig).sort()) ===
    JSON.stringify(['access_token', 'refresh_token']));

  const wl = columnsOf('workout_logs', mig).map((c) => c.name);
  t('workout_logs is found despite QUOTED identifiers (the third miss)',
    wl.includes('user_id') && wl.includes('duration_minutes'), `${wl.length} columns`);

  const ae = columnsOf('audit_events', mig).map((c) => c.name);
  t('audit_events picks up ALTER-added columns (delta, changed_columns)',
    ae.includes('delta') && ae.includes('changed_columns'), `${ae.length} columns`);

  t('RLS is detected despite multi-space formatting (the second miss)',
    ['payments', 'user_integrations', 'admin_role_assignments'].every((x) => rlsEnabled(x, mig)));

  let threw = false;
  try { columnsOf('a_table_that_does_not_exist', mig); } catch { threw = true; }
  t('an unknown table THROWS rather than returning []', threw);

  console.log(fails.length ? `\n  FAIL — ${fails.length} self-test(s) failed\n` : '\n  OK — schema-facts self-test passed\n');
  process.exit(fails.length ? 1 : 0);
}

if (process.argv[2] === 'columns') {
  for (const c of columnsOf(process.argv[3])) console.log(`  ${c.name.padEnd(28)} ${c.type.slice(0, 50).padEnd(52)} ${c.source}`);
}
