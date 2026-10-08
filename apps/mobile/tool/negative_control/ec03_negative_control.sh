#!/usr/bin/env bash
set -euo pipefail

# EC-03 — negative control for the intake false-completion end-to-end rung.
#
# The production guard is apps/mobile/test/widget/ec03_intake_false_completion_e2e_test.dart.
# Its second arm landed in the SAME commit that closed the defect it describes, so no CI run
# has ever observed it fail. QA_CLOSURE_STANDARD §2 defines VERIFIED IN CI as a check that
# "fails against the pre-fix tree and passes against the post-fix tree, IN CI" — this harness
# supplies the missing half. It follows wrk02/ec23's convention exactly: mutate the committed
# tree, require the declared failure, restore byte-identically, require the pass again.
#
# THE MUTATION IS THE HISTORICAL SHAPE, NOT A SYNTHETIC ONE. Before the fix, `_finish()`
# wrapped the entire save in `if (uid != null) { … }` and set the completion state
# unconditionally afterwards — so a null uid skipped the save and the flow still rendered
# IntakeCompletePage. Re-collapsing the explicit null arm back into that wrapper restores
# precisely that tree, and nothing else about the method changes.
#
# EXACTLY ONE OF THE TWO ARMS MUST BREAK. The first arm covers a save that was ATTEMPTED and
# failed, which the original EC-03 fix already handled; it must keep passing against the
# mutated tree. If both arms fail, the mutation reached further than declared and the harness
# refuses the run — a control that breaks everything proves nothing about what it aimed at.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)"
FLOW="$ROOT/apps/mobile/lib/features/onboarding/presentation/intake_flow_screen.dart"
TEST="$ROOT/apps/mobile/test/widget/ec03_intake_false_completion_e2e_test.dart"

ARM_SESSION='a SESSION LOST MID-FLOW'
ARM_FAILED_SAVE='a SAVE THAT FAILS'

die() {
  echo "ERROR: $*" >&2
  exit 1
}

cd "$ROOT/apps/mobile"

git diff --quiet -- "$FLOW" || die "intake_flow_screen.dart already modified"
git diff --cached --quiet -- "$FLOW" || die "intake_flow_screen.dart already staged"

TMP_FLOW="$(mktemp)"
cleanup() {
  if [[ -f "$TMP_FLOW" ]]; then
    cp "$TMP_FLOW" "$FLOW" 2>/dev/null || true
    rm -f "$TMP_FLOW"
  fi
}
trap cleanup EXIT

cp "$FLOW" "$TMP_FLOW"

echo "baseline: both EC-03 arms must pass"
flutter test "$TEST"

echo
echo "mutating: collapsing the explicit null-uid arm back into 'if (uid != null)'"

python3 - "$FLOW" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
src = p.read_text()

# The post-fix shape, anchored on the two lines that cannot appear anywhere else in the
# file: the explicit null test and the bare block that replaced the old wrapper.
start = src.find('    if (uid == null) {')
if start < 0:
    raise SystemExit('the null-uid arm was not found — the fix may have moved; the '
                     'contract must be reviewed, not the guard')
end = src.find('    {\n', start)
if end < 0:
    raise SystemExit('the bare block that replaced the old wrapper was not found')

mutated = src[:start] + '    if (uid != null) {\n' + src[end + len('    {\n'):]
if mutated == src:
    raise SystemExit('the mutation changed nothing')
if 'if (uid == null) {' in mutated:
    raise SystemExit('the null-uid arm survived the mutation')
p.write_text(mutated)
PY

grep -Fq 'if (uid != null) {' "$FLOW" \
  || die "the mutated tree does not carry the pre-fix wrapper"
grep -Fq 'not signed in' "$FLOW" \
  && die "the mutated tree still carries the post-fix message — the mutation under-reached"
echo "mutated tree carries the pre-fix 'if (uid != null)' wrapper"

echo
echo "mutated: the session-lost arm must fail, and the failed-save arm must NOT"

set +e
OUTPUT="$(flutter test "$TEST" 2>&1)"
RC=$?
set -e

printf '%s\n' "$OUTPUT"

# The exit code is the authoritative failure signal — Flutter's summary format differs
# between local and CI runners.
[[ "$RC" -ne 0 ]] || die "the EC-03 guard unexpectedly passed against the mutated tree"

printf '%s\n' "$OUTPUT" | grep -Fq "$ARM_SESSION" \
  || die "expected EC-03 failure not observed: $ARM_SESSION"

# SET EQUALITY, BOTH DIRECTIONS. Flutter prints a "Failing tests:" block listing each failed
# test's file and name; the failed-save arm must not be in it.
FAILING="$(printf '%s\n' "$OUTPUT" | sed -n '/^Failing tests:/,$p')"
if printf '%s\n' "$FAILING" | grep -Fq "$ARM_FAILED_SAVE"; then
  die "the mutation also broke the failed-save arm, which the original fix already closed — \
it reached further than declared, so this run proves nothing about the arm under test"
fi
echo "only the session-lost arm failed, exactly as declared"

echo
echo "restore: committed implementation"
cp "$TMP_FLOW" "$FLOW"
git diff --quiet -- "$FLOW" || die "intake_flow_screen.dart was not restored exactly"

echo
echo "restored: both EC-03 arms must pass"
flutter test "$TEST"

echo
echo "RESULT: PASS"
echo "Evidence class: EC-03 PRE-FIX / POST-FIX GUARD EVIDENCE, IN CI"
