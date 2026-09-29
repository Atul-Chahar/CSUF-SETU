# CLAUDE.md — Agent Context for SETU

This file is read automatically by Claude Code and other coding agents. It tells any
agent working in this repository what we are building, what the rules are, and what
mistakes to avoid.

**Human teammates: read this too. It is the shortest accurate summary of the project.**

---

## 1. What this project is

SETU turns dashcam video of Indian roads into deduplicated municipal repair tickets.

Pipeline in one line:

```
video + GPS + accelerometer → detect issues → merge duplicates by location → severity score → ticket → site engineer
```

This is a college capstone project (Polaris School of Technology, CSUF 2025–2029,
Project No. 4: "Road Infra Issues Detection System"). It is graded. It is public.
It is Apache 2.0 licensed.

**Team:** Atul Chahar (pipeline, geospatial, mobile capture, dashboard) and
Gyanranjan Panda (backend services, API, ticketing, scale). Both work on the CV model.

---

## 2. The single most important thing to understand

**The AI model is not the hard part. Deduplication is.**

One pothole appears in ~40 consecutive video frames. Drive the road again and it
appears 40 more times. Naive systems create 80 tickets for one pothole. A municipal
department receiving thousands of duplicates stops trusting the tool and stops using it.

Every design decision in this repo should be checked against one question:
**"Does this help produce one correct ticket per real-world problem?"**

If a change improves model accuracy but makes duplicates worse, it is a bad change.

---

## 3. Non-negotiable rules

### Rule 1 — Every claim must be verifiable by one command
Any number that appears in a README, a slide, a demo, or a commit message must also
appear in `docs/EVALUATION.md` next to the command that produces it.
`./scripts/verify-claims.sh` must exit non-zero if any claim has stopped being true.

Do not write "our model is 94% accurate" anywhere unless the script can prove it.

### Rule 2 — Never train on the evaluation set
`data/eval-set/` contains hand-labelled frames from roads we actually drive. It is
sacred. It never goes into a training run, not even by accident, not even "just to see".
Any script that reads `data/eval-set/` for training purposes is a bug.

### Rule 3 — Honest READMEs
State plainly which parts are working and which are mock, preview, or planned.
This is copied from KAVACH, which listed what it did *not* build and won anyway.
Overstating what works is the fastest way to lose credibility with an evaluator.

### Rule 4 — Point issues and segment issues are different shapes
A pothole is a **point** (one latitude/longitude).
A missing footpath is a **segment** (a stretch of road, e.g. 400 metres).
The data model must handle both from the start. Do not model everything as a point
and try to patch it later.

### Rule 5 — Plain English in all documentation
Our audience includes evaluators, municipal staff, and teammates who did not write
the code. Write short sentences. Explain every technical term the first time it appears,
or link to `docs/GLOSSARY.md`. Avoid jargon where an ordinary word works.

---

## 4. Architecture at a glance

Six layers. Full detail in `docs/ARCHITECTURE.md`.

| Layer | Name | What it does | Owner |
|---|---|---|---|
| L1 | Capture | Android app: video keyframes + GPS + accelerometer, offline-first | Atul |
| L2 | Detection | YOLO model finds things that are **present** (potholes, manholes, cracks) | Both |
| L3 | Absence reasoning | Segmentation + OpenStreetMap priors find things that are **missing** | Atul |
| L4 | Geo-fusion | Project to ground, cluster with DBSCAN, one cluster = one issue | Atul |
| L5 | Severity & ticketing | Score the issue, run the 6-state lifecycle, route to a department | Gyanranjan |
| L6 | Dashboard | MapLibre + OpenStreetMap map, ticket queue, before/after evidence | Gyanranjan |

---

## 5. Things that are easy to get wrong

**The accelerometer is a real signal, not decoration.**
A pothole strike produces a vertical (Z-axis) spike. A shadow on the road does not
shake the car. This gives us a second, camera-independent confirmation channel for
free. Do not drop it to simplify the capture app.

**Epsilon must exceed GPS error.**
Phone GPS is roughly ±5 metres. Our DBSCAN clustering distance (epsilon) is ~6–8 m.
Set epsilon too tight and one pothole splits into three tickets — the exact failure
we are trying to prevent. Tune this against measured duplicate rate, never intuition.

**You cannot detect an absence with an object detector.**
An object detector fires when something is present. "Missing zebra crossing" and
"no footpath zone" require an *expectation* from outside the image — the OpenStreetMap
road graph. See `docs/ABSENCE_DETECTION.md`. Do not try to solve this by adding a
"missing_crossing" class to YOLO. It will not work.

**Ultralytics YOLO is AGPL-3.0.**
Fine for this project because we publish our source. It becomes a real constraint if
anyone later wants to commercialise SETU. Flag it, do not silently ignore it.

---

## 6. What we deliberately did NOT reuse

Four public pothole repos were audited and rejected. Full reasoning in
`docs/REPO_AUDIT.md`. Summary:

- One has **no licence at all** (all rights reserved — legally unusable here)
- One is a whole-frame classifier with no bounding boxes (cannot locate anything)
- One is a 21 KB abandoned Flutter stub
- One is three notebooks wrapping three lines of Ultralytics API calls

If a future agent suggests "let's just fork an existing pothole detector to save time",
read `docs/REPO_AUDIT.md` first. This decision was made deliberately, not from ignorance.

---

## 7. Conventions

- **Python** for the model and pipeline work. Type hints on public functions.
- **Kotlin / Jetpack Compose** for the Android capture app.
- **Domain logic stays pure.** Geospatial clustering and severity scoring must be
  testable with no device, no network, and no GPU. Borrowed from KAVACH, where
  `domain/` has zero Android imports.
- **Commit messages** say what changed and why, not "update files".
- **Tests** before a phase gate is declared passed.

---

## 8. Current state

**Phase 0 — planning and setup.** No model trained yet. No app built yet.
See `docs/ROADMAP.md` for the 7 phases and `docs/PHASE_1.md` for what happens first.

When you finish work, update this section so the next agent knows where things stand.
