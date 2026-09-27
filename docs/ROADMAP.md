# Roadmap — 12 weeks, 7 phases

Each phase ends at a **gate**. A gate is something measurable, not a feeling.
"The model seems better" is not a gate. "mAP@50 on the held-out set is 0.61" is a gate.

We do not start a phase until the previous gate has passed and the number is written
into `EVALUATION.md`.

---

## Phase 0 — Foundations and the honesty harness
**Week 1**

The highest-leverage week in the project, and almost none of it is machine learning.

- [ ] Copy `verify-claims.sh`, `docs/EVALUATION.md`, the detekt config and the CI
      workflow from `KAVACH_IQOO` and point them at this repo
- [ ] **Submit the IDD access request** — this is the long pole, do it on day one
      (see `DATA.md` §2)
- [ ] Decide the data model: point issues vs segment issues (see `ABSENCE_DETECTION.md` §6)
- [ ] Download RDD2022, convert the India split to YOLO format
- [ ] Agree the work split and write it into `TEAM.md`

> **GATE:** CI is green and `./scripts/verify-claims.sh` runs and passes on a project
> that does nothing yet.

*Why this matters:* having a falsifiable claims harness from the first commit means every
claim we make for the next 12 weeks has to survive contact with it. Adding it in week 10
is worthless — by then the claims are already written.

---

## Phase 1 — Data and the held-out set
**Weeks 2–3**

- [ ] Hand-label 200–300 frames from roads we actually drive → `data/eval-set/`
- [ ] Cover the hard conditions on purpose: wet, dusk, shadow, tar patches
- [ ] Two people label a shared subset independently, compare, resolve disagreements
- [ ] Fine-tune YOLOv8n on the RDD2022 India split
- [ ] Run it against the held-out set

> **GATE:** a real mAP@50 number, measured on a set nobody trained on, written into
> `EVALUATION.md`.

*Expect this number to be mediocre.* That is correct and healthy. It is a baseline, not a
result. A suspiciously high first number almost always means the test set leaked into
training.

---

## Phase 2 — Detector v1 and the negative guard list
**Weeks 4–5**

- [ ] Scale up to YOLOv8s or v8m
- [ ] Add augmentation for rain, night, motion blur (see `DATA.md` §6)
- [ ] Produce **per-class** precision–recall curves, not one accuracy number
- [ ] Catalogue every false-positive mode observed, with example images
- [ ] Write the negative guard list from that catalogue

> **GATE:** a documented list of false-positive modes, each with either a guard that
> addresses it or an explicit written note that we accept the risk.

*The guard list is the KAVACH technique.* KAVACH reached a 0% false-positive rate using
40 such rules. They are just rules — no extra model, no extra training. This is the
cheapest accuracy win available to us.

---

## Phase 3 — Capture app
**Weeks 6–7**

- [ ] Android app: keyframe capture, GPS, accelerometer, offline buffer, upload
- [ ] Calibration screen for camera mount height and pitch angle
- [ ] Verify frame timestamps and telemetry timestamps actually align

> **GATE:** one real drive recorded end to end, with frames and telemetry correctly
> aligned in time.

*This should be the fastest phase.* Atul has built this exact thing before in AEGIS —
offline-first GPS breadcrumb capture with a local database. It is largely a port.

**Do not skip calibration.** Ground projection is impossible without mount height and
pitch, and retrofitting it means re-driving every route.

---

## Phase 4 — Geo-fusion — the crown jewel
**Weeks 8–9**

- [ ] Ground projection from bounding box to real-world coordinates
- [ ] DBSCAN clustering, class-constrained, haversine metric
- [ ] OpenStreetMap way snapping so issues attach to named roads and wards
- [ ] **The epsilon experiment:** drive one road five times, count potholes by hand,
      sweep epsilon 2–20 m, pick where the counts match

> **GATE:** a measured **duplicate rate** published in `EVALUATION.md`.
> One real pothole driven past three times must produce exactly one ticket.

*This is the gate that matters most.* It is the number that decides whether a municipal
department keeps using SETU. Model accuracy is secondary to it.

---

## Phase 5 — Absence detection — the research stretch
**Week 10**

- [ ] Train segmentation on IDD
- [ ] OSM junction priors → missing / faded zebra crossing candidates
- [ ] Continuous-run analysis → no-footpath zones

> **GATE:** either a working absence flag **or** a shipped coverage metric.
> One of them, done properly. Not both, half-finished.

The fallback is declared in advance in `ABSENCE_DETECTION.md` §7. If by mid-week the
binary judgement is not converging, switch to the coverage metric without guilt — it is
still a genuinely useful planning tool for a municipality.

---

## Phase 6 — Ticketing and dashboard
**Week 11**

- [ ] Six-state lifecycle: New → Verified → Assigned → In Progress → Resolved → Fix Verified
- [ ] Ward routing and SLA tracking
- [ ] MapLibre dashboard: severity map, ticket queue, before/after evidence pairs

> **GATE:** a detection becomes an assigned ticket without any human touching a database.

---

## Phase 7 — Edge port and final evaluation
**Week 12**

- [ ] Convert the model to TFLite or NCNN, run on-device
- [ ] Measure inference latency and battery drain honestly
- [ ] Final `verify-claims.sh` run — every claim green
- [ ] Demo runbook in the KAVACH format
- [ ] Write the honest "what we did not build" section

> **GATE:** every number in the README reproducible by one command, on a machine that
> has never seen the project.

---

## Dependency notes

```
Phase 0 ─┬─→ Phase 1 ──→ Phase 2 ──┐
         │                          ├──→ Phase 4 ──→ Phase 6 ──→ Phase 7
         └─→ Phase 3 ───────────────┘
                                    
         IDD request (P0) ······················→ Phase 5
```

- **Phase 3 (capture app) does not depend on Phase 1 or 2.** If model training stalls,
  build the app in parallel rather than waiting.
- **Phase 4 needs both** a working detector and real captured drives.
- **Phase 5 depends on the IDD request from Phase 0**, which is why it goes in on day one.

---

## What we will cut if we fall behind

Decided in advance, in this order, so we are not making the decision under pressure:

1. **Night-time performance** — measure it, do not optimise for it
2. **On-device port (Phase 7)** — server-side inference is a valid demo; say so honestly
3. **Absence detection** → drop to the coverage-metric fallback
4. **Manhole and footpath classes** → ship pothole and cracks properly

**We will not cut:** deduplication, the evaluation harness, or honest documentation.
Those are the project. Everything else is negotiable.
