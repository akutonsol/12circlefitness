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

The migration durability guard is **static** — it reads committed migration
source, needs no credentials and contacts nothing:

```bash
node supabase/tests/security/migration-durability-guard.mjs
node supabase/tests/security/migration-durability-guard.mjs --self-test
```

`npm run test:security` from the repo root does the same thing.

Keys come from `supabase projects api-keys --project-ref <ref>`. They are never
committed; `ids.json` (the fixture UUIDs) is generated, not authored.

## Safety

* The harness **refuses to run against the production project ref** (`lib.mjs`).
* It only ever touches its own `p1-*@qa.12circle.test` fixtures, and the rows it
  creates carry a `P1` marker and are torn down.
* `setup-identities.mjs` is idempotent.
* A member of the 116 wrapper class whose guard is **known stripped** is not
  probed by `d04` §8 — calling it would exercise the open hole rather than test
  a boundary (closure standard §5.2). The exemption is registered in
  `migration-durability-guard.mjs`'s `KNOWN_OPEN`, names its finding, and is
  reported on every run.

## I-MIG-03 posture — records, not yet enforcing

`migration-durability-guard.mjs` currently runs in **records-the-posture** mode:
a strip event listed in `KNOWN_OPEN` is printed in full and not counted as a
failure; any *other* unrestored strip is fatal. Exactly one entry is registered
— **F-J-01 / SEC-R1**, `materialize_program_week`, whose authorization wrapper
migration 119 dropped and nothing restores. It is detected, not fixed.

Promotion to enforcement belongs to **Wave 2 task 2A**: when migration 124
restores the wrapper, `KNOWN_OPEN` empties, `d04` §8 probes all five members,
and the guard's mode line becomes ENFORCING. A `KNOWN_OPEN` entry that outlives
its defect is itself reported as a failure, so the exemption cannot rot.

**The guard is not yet wired into CI** — that needs one step in
`.github/workflows/ci.yml`'s `static-guards` job, which is outside this task's
scope. Until then it is FIXED IN CODE only, never VERIFIED IN CI.

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
| `migration-durability-guard.mjs` | **I-MIG-03** — static: no migration may redefine a function carrying an authorization wrapper, a `search_path` pin or a SECURITY DEFINER boundary without carrying it forward |

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
