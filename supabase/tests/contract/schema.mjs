// Derives the `public` schema (tables → columns) from supabase/migrations by
// replaying CREATE TABLE / ALTER TABLE ADD|DROP|RENAME COLUMN in file order.
//
// This is the *offline* source of truth for the contract guard. It was verified
// byte-exact against a live `supabase db dump --linked` of QA
// (eyqtldjqpgpljlqvpowh) on 2026-08-24: 91 tables, 0 column drift. Views are
// listed separately because their column set comes from a SELECT list, not DDL.
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const MIGRATIONS = 'supabase/migrations';

// Views are not derived from DDL; a reference to one is not checked column-wise.
export const VIEWS = new Set([
  'coach_client_workout_stats',
  'conversation_participant_profiles',
  'exercise_certifications',
  'exercises',
  'public_profiles',
]);

// `.from()` names that are Storage buckets, not relations.
export const STORAGE_BUCKETS = new Set(['avatars', 'exercise-media', 'progress-photos']);

const stripComments = (sql) =>
  sql.replace(/\/\*[\s\S]*?\*\//g, '').replace(/--[^\n]*/g, '');

function splitTopLevel(body) {
  const out = [];
  let cur = '', depth = 0;
  for (const ch of body) {
    if (ch === '(') depth++;
    if (ch === ')') depth--;
    if (ch === ',' && depth === 0) { out.push(cur); cur = ''; continue; }
    cur += ch;
  }
  out.push(cur);
  return out;
}

export function deriveSchema(dir = MIGRATIONS) {
  const tables = new Map();
  const files = readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();

  for (const f of files) {
    const sql = stripComments(readFileSync(join(dir, f), 'utf8'));

    const createRe =
      /create\s+table\s+(?:if\s+not\s+exists\s+)?(?:public\.)?"?([a-z0-9_]+)"?\s*\(([\s\S]*?)\n\)\s*;/gi;
    for (const m of sql.matchAll(createRe)) {
      const t = m[1];
      const cols = tables.get(t) ?? new Set();
      for (const raw of splitTopLevel(m[2])) {
        const c = raw.trim();
        if (/^(constraint|check|primary\s+key|unique|foreign\s+key|exclude)\b/i.test(c)) continue;
        const cm = /^"?([a-z0-9_]+)"?\s/.exec(c);
        if (cm) cols.add(cm[1]);
      }
      tables.set(t, cols);
    }

    const alterRe =
      /alter\s+table\s+(?:if\s+exists\s+)?(?:public\.)?"?([a-z0-9_]+)"?\s+([\s\S]*?);/gi;
    for (const m of sql.matchAll(alterRe)) {
      const t = m[1], clause = m[2];
      for (const a of clause.matchAll(/add\s+column\s+(?:if\s+not\s+exists\s+)?"?([a-z0-9_]+)"?/gi)) {
        if (!tables.has(t)) tables.set(t, new Set());
        tables.get(t).add(a[1]);
      }
      for (const a of clause.matchAll(/drop\s+column\s+(?:if\s+exists\s+)?"?([a-z0-9_]+)"?/gi)) {
        tables.get(t)?.delete(a[1]);
      }
      for (const a of clause.matchAll(/rename\s+column\s+"?([a-z0-9_]+)"?\s+to\s+"?([a-z0-9_]+)"?/gi)) {
        if (!tables.has(t)) tables.set(t, new Set());
        tables.get(t).delete(a[1]);
        tables.get(t).add(a[2]);
      }
    }
  }
  return tables;
}
