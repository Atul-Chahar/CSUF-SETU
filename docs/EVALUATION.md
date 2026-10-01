# Evaluation — every claim, and the command that proves it

**This file exists because a project that says "94% accurate, zero duplicates, fully
automatic" is worth nothing unless someone who does not trust us can check it in under
a minute.**

Borrowed directly from KAVACH, where this discipline was a major reason the project won
the iQOO Hackathon 2026 Bangalore City Battle.

---

## The one command

```bash
./scripts/verify-claims.sh
```

It prints every claim with its **measured** value and **exits non-zero if any single one
has stopped being true.** No GPU needed, no device needed, no network needed.

**If a number anywhere — README, slide, demo, verbal answer — disagrees with this file,
this file is right.**

---

## Current status

> **Phase 0.** The harness runs. Most claims are still `PENDING` because the thing they
> measure does not exist yet. This is expected and correct — the harness is deliberately
> built *before* there is anything to verify, so that every future claim has to pass
> through it.

```
  PENDING  Detection mAP@50 on held-out set              phase 1
  PENDING  Per-class precision / recall                  phase 2
  PENDING  Documented false-positive modes               phase 2
  PENDING  Frame/telemetry timestamp alignment           phase 3
  PENDING  Duplicate rate (the headline number)          phase 4
  PENDING  Epsilon vs GPS error experiment               phase 4
  PENDING  Absence detection OR coverage metric          phase 5
  PENDING  Detection → assigned ticket, no manual step   phase 6
  PENDING  On-device inference latency                   phase 7
  PENDING  On-device battery drain per hour              phase 7
  PASS     Eval set never used in training               0 references
  PASS     Domain logic has no I/O imports               0
```

---

## Claims, criterion by criterion

### Detection quality

| Claim | Measured by | Status |
|---|---|---|
| mAP@50 on the held-out set | `scripts/eval_detector.py --set data/eval-set` | PENDING — Phase 1 |
| Per-class precision and recall | same, `--per-class` | PENDING — Phase 2 |
| Performance in wet / shadow / dusk conditions | same, `--slice condition` | PENDING — Phase 2 |

We report **precision and recall separately, per class**. A single accuracy number hides
which of the two we traded away, and for this project a false positive costs a wasted
crew visit while a false negative costs one missed pothole. They are not equivalent and
should never be averaged into one figure.

### Deduplication — the headline

| Claim | Measured by | Status |
|---|---|---|
| Duplicate rate | `scripts/eval_dedup.py --route data/eval-set/routes/` | PENDING — Phase 4 |
| One pothole, three passes, one ticket | `pytest tests/test_dedup.py` | PENDING — Phase 4 |
| Chosen epsilon exceeds measured GPS error | `scripts/epsilon_sweep.py` | PENDING — Phase 4 |

```
duplicate_rate = (tickets_created / real_distinct_problems) − 1
```

Target: **≤ 0.2** — that is, at most 1.2 tickets per real problem.

### Integrity guarantees

| Claim | Measured by | Status |
|---|---|---|
| The evaluation set is never read by training code | grep for `eval-set` in training paths | PASS |
| Domain logic is pure — no network, no filesystem, no device | import scan of `domain/` | PASS |
| Every README number appears in this file | `scripts/check_claims_coverage.py` | PENDING |

---

## What we have NOT built

**This section is mandatory and gets filled in honestly as we go.**

KAVACH listed the one component that was integrated but switched off, and won anyway.
Evaluators trust a team that volunteers its limitations far more than one that has to be
caught out.

Current honest list at Phase 0:

- Nothing is built yet. This is a planning-stage repository.
- Static CCTV support is **explicitly out of scope** — dashcam only (see `PRD.md` §4)
- No integration with a real municipal ITMS — we build the ticket format and an export,
  but we have no access to a live department system
- We will measure night-time performance but will not promise it

---

## How to add a claim

1. Write the number into this file with the exact command that produces it.
2. Add the check to `scripts/verify-claims.sh`.
3. Confirm the script fails if you deliberately break the claim. **A check that cannot
   fail is not a check.**
