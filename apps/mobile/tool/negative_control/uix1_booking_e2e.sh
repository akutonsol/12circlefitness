#!/usr/bin/env bash
set -euo pipefail

# UIX-1 / M-03 — VERIFIED END-TO-END runner.
#
# Drives integration_test/uix1_booking_e2e_test.dart on the Linux desktop target
# and refuses to report success unless the driver actually reached the real
# booking surface. Follows wrk01_live_probe.sh: preflight, run, then a
# discrimination pass over the marker channel so an infrastructure failure can
# never be read as end-to-end evidence.
#
# No credential of its own: the probe reads dart_defines/qa.json, exactly as the
# I-WRK-01 probe does. No service-role key, no GitHub secret.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)"
PROBE="integration_test/uix1_booking_e2e_test.dart"
DEVICE="${PROBE_DEVICE:-linux}"
DEFINES="--dart-define-from-file=dart_defines/qa.json"
RUN_ID="${PROBE_RUN_ID:-local-$(date +%s)}"

die()   { echo "FAIL: $*" >&2; exit 1; }
infra() { echo "INFRASTRUCTURE FAILURE: $*" >&2; exit 1; }

cd "$ROOT/apps/mobile"

echo "── STEP 0 · PREFLIGHT ──────────────────────────────────────────────────"
flutter --version
echo "cwd:    $(pwd)"
echo "target: $PROBE"
echo "device: $DEVICE"
echo "run id: $RUN_ID"
[[ -f "$PROBE" ]] || infra "the probe target $PROBE does not exist."
flutter devices || true
flutter devices | grep -qi "$DEVICE" || infra "no '$DEVICE' device is available."

LOG_E2E="$(mktemp)"
LOG_CLEAN="$(mktemp)"

# Layer A2. Runs whatever happens to the e2e leg, so a crash before the driver's
# own finally-block still retires the fixture. Layer B (the workflow's
# if:always() step) sits behind this one.
cleanup_always() {
  local crc
  echo
  echo "── CLEANUP (harness) ─────────────────────────────────────────────────"
  set +e
  flutter test "$PROBE" -d "$DEVICE" $DEFINES \
    --dart-define=PROBE_RUN_ID="$RUN_ID" \
    --dart-define=PROBE_MODE=cleanup 2>&1 | tee "$LOG_CLEAN"
  crc=${PIPESTATUS[0]}
  set -e
  if ! grep -qF 'UIX1-MARK CLEANUP verified availability=0 active-relationships=0' "$LOG_CLEAN"; then
    echo "WARNING: harness cleanup did not prove an empty fixture (rc=$crc)." >&2
    echo "         The workflow's if:always() step is the remaining guarantee." >&2
  fi
}
trap cleanup_always EXIT

echo
echo "── STEP 1 · END-TO-END LEG ─────────────────────────────────────────────"
set +e
flutter test "$PROBE" -d "$DEVICE" $DEFINES \
  --dart-define=PROBE_RUN_ID="$RUN_ID" \
  --dart-define=PROBE_MODE=e2e 2>&1 | tee "$LOG_E2E"
RC=${PIPESTATUS[0]}
set -e

echo
echo "── STEP 2 · DISCRIMINATION ─────────────────────────────────────────────"

# Infrastructure first: these separate "the surface is broken" from "the runner
# never got there". Each is an INFRASTRUCTURE FAILURE, not evidence.
grep -qF 'UIX1-MARK BOOT ok' "$LOG_E2E" \
  || infra "the run never initialised Supabase."
grep -qF 'UIX1-MARK FIXTURE collision-check clean prior-active=0' "$LOG_E2E" \
  || infra "the collision check did not report a clean slate — a pre-existing active relationship, or the check never ran."
grep -qF 'UIX1-MARK FIXTURE relationship active=1' "$LOG_E2E" \
  || infra "the active relationship fixture was not created."
grep -qE 'UIX1-MARK FIXTURE availability rows=[1-9]' "$LOG_E2E" \
  || infra "no availability slots were seeded."
grep -qF 'UIX1-MARK ROUTE navigated=/appointments' "$LOG_E2E" \
  || infra "the driver never navigated to the real route."

# Acceptance. A1 · A2 · A3, each required explicitly — a green exit alone is not
# accepted as proof that the assertions ran.
grep -qF 'UIX1-MARK A1 surface-reached=true' "$LOG_E2E" \
  || die "A1: /appointments did not render the booking surface."
grep -qF 'UIX1-MARK A1 paywall-locked=false' "$LOG_E2E" \
  || die "A1: PaywallGate locked a client whose client_plan() is coach_guided."
grep -qF 'UIX1-MARK A2 coach-rendered=true' "$LOG_E2E" \
  || die "A2: the real coach identity never reached the widget tree."
grep -qF 'UIX1-MARK A3 ready-state=true' "$LOG_E2E" \
  || die "A3: the surface never reached the ready state."
grep -qF 'UIX1-MARK A3 not-No Coach Selected Yet=true' "$LOG_E2E" \
  || die "A3: the surface resolved to noCoach."
grep -qF "UIX1-MARK A3 not-Couldn't load your bookings=true" "$LOG_E2E" \
  || die "A3: the surface resolved to the error state."
grep -qF 'UIX1-MARK A3 not-No Slots Available=true' "$LOG_E2E" \
  || die "A3: the surface resolved to noSlots."
grep -qF 'UIX1-MARK ASSERT-ALL PASS' "$LOG_E2E" \
  || die "the acceptance block did not complete."

# The exit code is the authoritative signal; the markers above prove WHICH
# assertions ran. Both are required, and no failure is tolerated.
[[ "$RC" -eq 0 ]] || die "the end-to-end leg exited $RC."

echo
echo "RESULT: PASS"
echo "Evidence class: UIX-1 VERIFIED END-TO-END — real route, real PaywallGate, real surface"
echo "NOT ESTABLISHED: the failure path (A4). See the probe header — _load() returns"
echo "                 at uid == null before its try/catch, so _LoadFailedState cannot"
echo "                 be reached without a production edit, an RLS change or a mock."
