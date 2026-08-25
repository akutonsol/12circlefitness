#!/usr/bin/env bash
# ENV-1 / ENV-2 · migration hygiene.
#
# Gate 0 row 0.7. Wave 0 found 20 migrations sitting untracked in the working
# tree, plus 15 historical migrations edited in place — a tree whose migration
# directory does not match its history cannot be promoted, because "replay from
# empty" and "what production actually ran" have quietly diverged.
#
#   .github/scripts/check-migration-hygiene.sh    (or: npm run check:migrations)
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
DIR=supabase/migrations
fail=0

# 1. Nothing untracked or modified. In CI this is near-tautological; run locally
#    it is the check that would have caught ENV-1 before it became 20 files.
dirty="$(git status --porcelain -- "$DIR")"
if [[ -n "$dirty" ]]; then
  echo "FAIL — $DIR is not clean:"
  echo "$dirty"
  echo "Every migration must be committed. An untracked migration is a schema"
  echo "change that exists on somebody's laptop and nowhere else."
  fail=1
else
  echo "OK — $DIR is clean and fully tracked."
fi

# 2. Every migration is NNN_snake_case.sql, so ordering is total and readable.
bad="$(git ls-files "$DIR" | xargs -n1 basename | grep -vE '^[0-9]{3}_[a-z0-9_]+\.sql$' || true)"
if [[ -n "$bad" ]]; then
  echo "FAIL — migration filenames do not match NNN_name.sql:"
  echo "$bad"
  fail=1
else
  echo "OK — all migration filenames conform."
fi

# 3. No two migrations share a number. Two files claiming 118 will apply in an
#    order nobody chose, and a CREATE OR REPLACE in the loser silently wins.
dupes="$(git ls-files "$DIR" | xargs -n1 basename | sed -E 's/^([0-9]{3})_.*/\1/' | sort | uniq -d || true)"
if [[ -n "$dupes" ]]; then
  echo "FAIL — duplicate migration numbers: $dupes"
  fail=1
else
  echo "OK — migration numbers are unique ($(git ls-files "$DIR" | wc -l | tr -d ' ') migrations)."
fi

exit $fail
