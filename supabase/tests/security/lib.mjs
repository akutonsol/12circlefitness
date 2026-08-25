// Live security regression harness.
//
// These suites run against a REAL Supabase project over the REST/RPC surface,
// with the same anon key and the same JWTs a phone would use. That is the point:
// a static SQL assertion cannot tell you whether PostgREST, the column grants,
// the policies and the triggers compose into an actual boundary. Every finding
// in the Phase 1 audit was reproduced here first and is now pinned here.
//
// SAFETY: the harness refuses to run against the production project. It only
// ever touches its own `p1-*@qa.12circle.test` fixtures.
//
// Usage:
//   export QA_URL=https://<ref>.supabase.co QA_ANON=... QA_SERVICE=...
//   node supabase/tests/security/run.mjs

export const URL_ = process.env.QA_URL;
export const ANON = process.env.QA_ANON;
export const SERVICE = process.env.QA_SERVICE;

const PROD_REF = 'nxdbooufqzkpslkcogxc';

if (!URL_ || !ANON || !SERVICE) {
  console.error('QA_URL, QA_ANON and QA_SERVICE must be set. See supabase/tests/security/README.md');
  process.exit(2);
}
if (URL_.includes(PROD_REF)) {
  console.error(`REFUSING TO RUN: ${PROD_REF} is the production project.`);
  process.exit(2);
}

// Fixture identities. Created on demand by setup-identities.mjs; all are
// flagged is_demo so they stay out of discovery surfaces.
export const IDENT = {
  victim:   { email: 'p1-victim@qa.12circle.test',   pw: 'P1-Probe-Victim-2026!',   role: 'client' },
  attacker: { email: 'p1-attacker@qa.12circle.test', pw: 'P1-Probe-Attacker-2026!', role: 'client' },
  coach:    { email: 'p1-coach@qa.12circle.test',    pw: 'P1-Probe-Coach-2026!',    role: 'coach'  },
  admin:    { email: 'p1-admin@qa.12circle.test',    pw: 'P1-Probe-Admin-2026!',    role: 'admin'  },
};

async function parse(res) {
  const t = await res.text();
  let body; try { body = t ? JSON.parse(t) : null; } catch { body = t; }
  return { status: res.status, ok: res.ok, body, headers: res.headers };
}

// ── auth ─────────────────────────────────────────────────────────────────────
export async function adminFindUser(email) {
  const r = await fetch(`${URL_}/auth/v1/admin/users?filter=${encodeURIComponent(email)}`,
    { headers: { apikey: SERVICE, Authorization: `Bearer ${SERVICE}` } });
  const { body } = await parse(r);
  return (body?.users || []).find(u => u.email === email) || null;
}

export async function ensureUser(key) {
  const { email, pw } = IDENT[key];
  let u = await adminFindUser(email);
  if (!u) {
    const r = await fetch(`${URL_}/auth/v1/admin/users`, {
      method: 'POST',
      headers: { apikey: SERVICE, Authorization: `Bearer ${SERVICE}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: pw, email_confirm: true }),
    });
    const { status, body } = await parse(r);
    if (status >= 300) throw new Error(`create ${email}: ${status} ${JSON.stringify(body)}`);
    u = body;
  } else {
    await fetch(`${URL_}/auth/v1/admin/users/${u.id}`, {
      method: 'PUT',
      headers: { apikey: SERVICE, Authorization: `Bearer ${SERVICE}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ password: pw, email_confirm: true }),
    });
  }
  return u.id;
}

const tokenCache = new Map();
export async function signIn(key) {
  if (tokenCache.has(key)) return tokenCache.get(key);
  const { email, pw } = IDENT[key];
  const r = await fetch(`${URL_}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: { apikey: ANON, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: pw }),
  });
  const { status, body } = await parse(r);
  if (status >= 300) throw new Error(`signIn ${email}: ${status} ${JSON.stringify(body)}`);
  tokenCache.set(key, body.access_token);
  return body.access_token;
}

// ── rest ─────────────────────────────────────────────────────────────────────
// who: 'anon' | 'service' | <jwt>
function hdrs(who, extra = {}) {
  const key = who === 'service' ? SERVICE : ANON;
  const bearer = who === 'anon' ? ANON : who === 'service' ? SERVICE : who;
  return { apikey: key, Authorization: `Bearer ${bearer}`, 'Content-Type': 'application/json', ...extra };
}

/** Plain read. `path` is everything after /rest/v1/, filters included. */
export async function rest(who, path, opts = {}) {
  const r = await fetch(`${URL_}/rest/v1/${path}`, {
    method: opts.method || 'GET',
    headers: hdrs(who, opts.headers),
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });
  return parse(r);
}

/**
 * Write exactly the way the Flutter client writes: `Prefer: return=minimal`,
 * i.e. no RETURNING clause.
 *
 * This matters. `return=representation` needs SELECT on every column, so on a
 * table that deliberately withholds a column (invite_token) it 403s for reasons
 * that have nothing to do with the policy under test — and would make an
 * unprotected table look protected. `count=exact` gives rows-affected through
 * the Content-Range header instead, with no column privilege required.
 *
 * Returns { status, affected } where affected is null when unavailable.
 */
export async function mutate(who, path, method, body) {
  const r = await fetch(`${URL_}/rest/v1/${path}`, {
    method,
    headers: hdrs(who, { Prefer: 'return=minimal,count=exact' }),
    body: body ? JSON.stringify(body) : undefined,
  });
  const p = await parse(r);
  const cr = r.headers.get('content-range');           // e.g. "*/3"
  const affected = cr && cr.includes('/') ? Number(cr.split('/')[1]) : null;
  return { status: p.status, body: p.body, affected: Number.isNaN(affected) ? null : affected };
}

/** A mutation is BLOCKED when it errors, or succeeds against zero rows. */
export const blocked = (m) => m.status >= 400 || m.affected === 0;
/** A mutation LANDED when it succeeded and touched at least one row. */
export const landed = (m) => m.status < 300 && (m.affected === null || m.affected > 0);

export async function rpc(who, fn, args = {}) {
  const r = await fetch(`${URL_}/rest/v1/rpc/${fn}`, {
    method: 'POST', headers: hdrs(who), body: JSON.stringify(args),
  });
  return parse(r);
}

/** Service-role helper — used only to arrange fixtures, never to assert. */
export async function svc(path, opts = {}) {
  const r = await fetch(`${URL_}/rest/v1/${path}`, {
    method: opts.method || 'GET',
    headers: { apikey: SERVICE, Authorization: `Bearer ${SERVICE}`, 'Content-Type': 'application/json',
               Prefer: opts.prefer || 'return=representation' },
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });
  return parse(r);
}

// ── reporting ────────────────────────────────────────────────────────────────
export const results = [];
let suiteStart = 0;

export function beginSuite() {
  suiteStart = results.length;
}

export function check(name, pass, detail) {
  results.push({ name, pass, detail });
  console.log(`  ${pass ? 'PASS' : 'FAIL'}  ${name}${detail ? `  — ${detail}` : ''}`);
  return pass;
}

export function section(t) {
  console.log(`\n── ${t} ${'─'.repeat(Math.max(2, 68 - t.length))}`);
}

export function summary(label) {
  const suiteResults = results.slice(suiteStart);
  const f = suiteResults.filter(r => !r.pass);

  console.log(
    `\n${'='.repeat(74)}\n${label}: ${suiteResults.length - f.length}/${suiteResults.length} passed`
  );

  if (f.length) {
    console.log('FAILURES:');
    f.forEach(r => console.log(`  x ${r.name} — ${r.detail || ''}`));
  }

  return f.length;
}


/** Row count of a PostgREST body; an error object counts as zero rows read. */
export const n = (b) => Array.isArray(b) ? b.length : 0;

export async function loadIds() {
  const { readFileSync } = await import('node:fs');
  const p = new URL('./ids.json', import.meta.url);
  try { return JSON.parse(readFileSync(p, 'utf8')); }
  catch { throw new Error('ids.json missing — run: node supabase/tests/security/setup-identities.mjs'); }
}
