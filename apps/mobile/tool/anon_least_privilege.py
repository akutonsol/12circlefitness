#!/usr/bin/env python3
"""Read-only least-privilege probe against the QA Supabase project.

WHAT IT ANSWERS
  1. Can an UNAUTHENTICATED caller read any table?  (PHI least privilege)
  2. Does a given relation exist at all?            (schema-vs-migration drift)
  3. Which storage buckets are served without auth? (media privacy)

WHY IT IS SAFE TO RUN
  * GET only. It never writes, never mutates, never creates a fixture.
  * `select=*&limit=0` with `Prefer: count=exact` returns a COUNT and NO ROWS,
    so no PHI is ever retrieved, printed or logged.
  * It refuses to run against the production ref, the same guard
    `supabase/tests/security/lib.mjs` applies.
  * The storage probe uses a fixed nonexistent object name, so it touches no
    user content.

WHY IT USES dart_defines/qa.json
  The security suites in `supabase/tests/security/` need QA_URL/QA_ANON/
  QA_SERVICE. The SERVICE key is required to provision test users, and is not
  available in every environment. The ANON key alone is enough for the three
  questions above, and it is already committed as the app's own QA config.

  Usage:  python3 tool/anon_least_privilege.py     (from apps/mobile)
"""
import json, os, sys, urllib.request, urllib.error

PROD_REF = 'nxdbooufqzkpslkcogxc'   # matches supabase/tests/security/lib.mjs
HERE = os.path.dirname(os.path.abspath(__file__))
cfg = json.load(open(os.path.join(HERE, '..', 'dart_defines', 'qa.json')))
URL = cfg['SUPABASE_URL'].rstrip('/')
ANON = cfg['SUPABASE_ANON_KEY']

if PROD_REF in URL:
    sys.exit(f'REFUSING TO RUN: {PROD_REF} is the production project.')

def _get(path, with_key=True, prefer=None):
    req = urllib.request.Request(f'{URL}{path}', method='GET')
    if with_key:
        req.add_header('apikey', ANON)
        req.add_header('Authorization', f'Bearer {ANON}')
    if prefer:
        req.add_header('Prefer', prefer)
    try:
        with urllib.request.urlopen(req, timeout=25) as r:
            return r.status, r.headers.get('Content-Range', ''), ''
    except urllib.error.HTTPError as e:
        return e.code, '', e.read()[:220].decode('utf-8', 'replace')
    except Exception as e:
        return 'ERR', '', str(e)[:80]


def table_state(t):
    """EXISTS / ABSENT / READABLE, from PostgREST's own error codes.

    42501  = permission denied for table -> the relation EXISTS and the `anon`
             ROLE has no GRANT. That is stronger than an RLS filter: RLS hides
             rows, a missing grant refuses the table.
    PGRST205 / 42P01 = the relation is not in the schema cache -> ABSENT.
    """
    s, cr, body = _get(f'/rest/v1/{t}?select=*&limit=0', prefer='count=exact')
    if s == 200:
        return 'READABLE', cr
    if '42501' in body:
        return 'EXISTS', ''
    if 'PGRST205' in body or '42P01' in body:
        return 'ABSENT', ''
    return f'OTHER({s})', body[:70]


def bucket_state(b):
    """PUBLIC / PRIVATE-OR-ABSENT, with NO credentials at all.

    A public bucket answers the public object route and reports NoSuchKey for
    a missing object. A private bucket refuses the route with NoSuchBucket —
    which an absent bucket also does, so the two are not distinguishable here.
    """
    probe = 'qa-nonexistent-probe-object-000.bin'
    s, _, body = _get(f'/storage/v1/object/public/{b}/{probe}', with_key=False)
    if 'NoSuchKey' in body:
        return 'PUBLIC (served without auth)'
    if 'NoSuchBucket' in body:
        return 'private or absent'
    return f'? {s} {body[:60]}'


if __name__ == '__main__':
    ref = URL.split('//')[1].split('.')[0]
    print(f'QA project {ref}  (production {PROD_REF} is refused)\n')

    tables = [t.strip() for t in open(os.path.join(HERE, 'qa_tables.txt'))
              if t.strip() and not t.startswith('#')]
    readable, absent = [], []
    for t in tables:
        state, extra = table_state(t)
        if state == 'READABLE':
            readable.append((t, extra))
        elif state == 'ABSENT':
            absent.append(t)
    print(f'tables probed          : {len(tables)}')
    print(f'readable by anon       : {len(readable)}   <-- must be 0')
    print(f'absent from QA         : {len(absent)}')
    for t, cr in readable:
        print(f'   *** ANON-READABLE: {t}  {cr}')
    for t in absent:
        print(f'   ABSENT (read by the app, created by no migration?): {t}')

    print('\nstorage buckets, probed with NO credentials:')
    for b in ['coach-media', 'exercise-media', 'avatars',
              'progress-photos', 'chat-media', 'messages']:
        print(f'   {b:18} {bucket_state(b)}')
