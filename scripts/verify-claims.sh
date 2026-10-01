#!/usr/bin/env bash
# verify-claims.sh — prove every claim SETU makes, or fail.
#
# Ported from KAVACH_IQOO, which used this pattern to verify 31 claims in one minute
# and won the iQOO Hackathon 2026 Bangalore City Battle.
#
# Rule: if a number appears in a README, a slide, or a demo, it appears here too,
# next to the command that produces it. If any claim stops being true, this exits 1.
#
# Usage:  ./scripts/verify-claims.sh
# No GPU, no device, no network required.

set -uo pipefail
cd "$(dirname "$0")/.."

PASS=0; FAIL=0; PENDING=0

pass()    { printf '  \033[32mPASS\033[0m     %-46s %s\n' "$1" "$2"; PASS=$((PASS+1)); }
fail()    { printf '  \033[31mFAIL\033[0m     %-46s %s\n' "$1" "$2"; FAIL=$((FAIL+1)); }
pending() { printf '  \033[33mPENDING\033[0m  %-46s %s\n' "$1" "$2"; PENDING=$((PENDING+1)); }

echo
echo "SETU — claim verification"
echo "========================================================================="
echo

# ---------------------------------------------------------------- integrity
# These are the claims that must hold from day one. They are the reason this
# script exists before any model does.

echo "Integrity guarantees"

# Claim: the evaluation set is never read by training code.
# Any hit here means a script could train on our held-out data, which would
# invalidate every accuracy number we ever publish.
LEAKS=$(grep -rln "eval-set" --include="*.py" --include="*.ipynb" \
          scripts/ notebooks/ backend/ 2>/dev/null \
          | xargs -r grep -l -E "mode=train|\.train\(|fit\(" 2>/dev/null | wc -l)
if [ "$LEAKS" -eq 0 ]; then
  pass "Eval set never referenced in training code" "$LEAKS references"
else
  fail "Eval set never referenced in training code" "$LEAKS FILES LEAK — see CLAUDE.md rule 2"
fi

# Claim: the eval set manifest exists and is being maintained.
if [ -f data/eval-set/MANIFEST.md ]; then
  pass "Eval set manifest present" "data/eval-set/MANIFEST.md"
else
  fail "Eval set manifest present" "MISSING"
fi

# Claim: every document referenced from the README actually exists.
MISSING_DOCS=0
while IFS= read -r doc; do
  [ -f "$doc" ] || { MISSING_DOCS=$((MISSING_DOCS+1)); echo "           missing: $doc"; }
done < <(grep -o 'docs/[A-Z_0-9]*\.md' README.md | sort -u)
if [ "$MISSING_DOCS" -eq 0 ]; then
  pass "All docs linked from README exist" "0 broken links"
else
  fail "All docs linked from README exist" "$MISSING_DOCS broken"
fi

# Claim: the agent context file exists. Teammates and agents both depend on it.
if [ -f CLAUDE.md ]; then
  pass "Agent context file present" "CLAUDE.md"
else
  fail "Agent context file present" "MISSING"
fi

echo
echo "Documentation"

DOC_COUNT=$(find docs -name '*.md' | wc -l)
pass "Documents in docs/" "$DOC_COUNT"

# Claim: the honest limitations section exists and is not empty.
if grep -q "What we have NOT built" docs/EVALUATION.md; then
  pass "Honest limitations section present" "docs/EVALUATION.md"
else
  fail "Honest limitations section present" "MISSING — see CLAUDE.md rule 3"
fi

echo
echo "Detection quality"
pending "Detection mAP@50 on held-out set"          "phase 1"
pending "Per-class precision / recall"              "phase 2"
pending "Per-condition slices (wet/shadow/dusk)"    "phase 2"
pending "Documented false-positive modes"           "phase 2"

echo
echo "Capture"
pending "Frame / telemetry timestamp alignment"     "phase 3"

echo
echo "Deduplication — the headline metric"
pending "Duplicate rate  (target <= 0.2)"           "phase 4"
pending "One pothole, three passes, one ticket"     "phase 4"
pending "Chosen epsilon exceeds measured GPS error" "phase 4"

echo
echo "Absence detection"
pending "Absence flag OR footpath coverage metric"  "phase 5"

echo
echo "Ticketing"
pending "Detection to assigned ticket, no manual step" "phase 6"

echo
echo "On-device"
pending "Inference latency on phone"                "phase 7"
pending "Battery drain per hour of capture"         "phase 7"

echo
echo "========================================================================="
printf '  %d passed · %d pending · %d failed\n' "$PASS" "$PENDING" "$FAIL"
echo

if [ "$FAIL" -gt 0 ]; then
  echo "  A claim has stopped being true. Fix it or delete the claim."
  echo
  exit 1
fi

echo "  All active claims verified. $PENDING claims awaiting their phase."
echo
exit 0
