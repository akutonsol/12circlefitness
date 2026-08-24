# Live security regression suites

These run against a **real Supabase project** over the REST/RPC surface, with the
same anon key and the same JWTs a phone would use.

That is the point. A static SQL assertion tells you a policy exists; it does not
tell you whether PostgREST, the column grants, the policies and the triggers
compose into an actual boundary. Every finding in `docs/PHASE_1_SECURITY_AUDIT.md`
was reproduced here first — the suites were written to FAIL against the
pre-remediation database and pass after it.

## Running

```bash
export QA_URL=https://<qa-project-ref>.supabase.co
export QA_ANON=<qa anon key>
export QA_SERVICE=<qa service_role key>

node supabase/tests/security/setup-identities.mjs   # once, or after a rebuild
node supabase/tests/security/run.mjs
```

`npm run test:security` from the repo root does the same thing.

Keys come from `supabase projects api-keys --project-ref <ref>`. They are never
committed; `ids.json` (the fixture UUIDs) is generated, not authored.

## Safety

* The harness **refuses to run against the production project ref** (`lib.mjs`).
* It only ever touches its own `p1-*@qa.12circle.test` fixtures, and the rows it
  creates carry a `P1` marker and are torn down.
* `setup-identities.mjs` is idempotent.

## Layout

| File | Covers |
|---|---|
| `lib.mjs` | harness: auth, REST/RPC helpers, reporting |
| `setup-identities.mjs` | creates victim / attacker / coach / admin + seed health data |
| `d01-coach-client-relationships.mjs` | D-01 — the authorization root |
| `d02-role-escalation.mjs` | D-02 — privilege columns, signup metadata, PAR-Q authority |
| `d03-weekly-checkins.mjs` | D-03 — health check-in RLS and the authorship split |
| `d04-rpc-execution.mjs` | Phase 1D — SECURITY DEFINER execution + arbitrary subject UUIDs |
| `d05-intelligence-substrate.mjs` | Phase 1E — engine substrate, provenance, programming |
| `d06-sweep-posture.mjs` | Phase 1F — schema-wide posture + F-01..F-07 |

## Writing a new assertion

Use `mutate()` for writes, not `rest()` with `Prefer: return=representation`.
`return=representation` needs SELECT on every column, so on a table that
deliberately withholds one (`coach_client_relationships.invite_token`) it 403s
for a reason unrelated to the policy under test — which would make an
**unprotected** table look protected. `mutate()` writes the way the Flutter
client does (`return=minimal`) and reads rows-affected from `Content-Range`.

`blocked(m)` means "errored, or affected zero rows". `landed(m)` means
"succeeded and touched at least one row". Assert with those, not with the status
code alone: a PATCH that RLS filters to zero rows returns **204**, not 403.
