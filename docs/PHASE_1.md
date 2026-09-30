# Phase 1 — Data and the held-out set

**Weeks 2–3 · Gate: a real mAP@50 on data nobody trained on**

> Phase 0 (week 1) comes first — see `ROADMAP.md`. This document covers what happens
> once the harness is running and RDD2022 is downloaded.

---

## The goal of this phase, in one line

**Get an honest first number.** Not a good number. An honest one.

Everything after this phase is measured against the baseline established here, so if the
baseline is dishonest — if the test data leaked into training — every improvement we
claim for the next ten weeks is meaningless.

---

## Task 1 — Build the evaluation set (do this FIRST)

**Before any training. Not after.**

If you build the test set after seeing the model's mistakes, you will unconsciously build
a test the model passes. This ordering is not a preference, it is the whole point.

### What to capture

Drive routes you can drive again. Repeat passes matter later in Phase 4.

| Condition | Target frames | Why it is on the list |
|---|---|---|
| Bright daylight, dry road | ~80 | The baseline case |
| Overcast or dusk | ~50 | Low contrast — the common failure mode |
| Wet road after rain | ~40 | Reflections are our worst false-positive source |
| Heavy shadow (trees, buildings) | ~40 | Second worst false-positive source |
| Night with headlights | ~30 | We measure it; we do not promise it |
| Fresh tar patches | ~20 | Looks like a pothole, is actually a repair |

**Total: 200–300 frames.**

The last row matters more than it looks. A fresh tar patch is dark, roughly circular, and
sits in the road surface — everything a pothole detector keys on. It is the single most
important negative example we can collect, and it becomes a negative guard in Phase 2.

### How to label

- Draw a tight box around each defect. Tight matters — loose boxes inflate our size
  estimates, which feed the severity score.
- Use the class list from `ARCHITECTURE.md` L2.
- Tools: LabelImg, CVAT, or Roboflow's free annotation tier. Any of them export YOLO
  format.

### The two-person check

**Both of you label the same 40 frames independently, then compare.**

Wherever you disagree, the *definition* is unclear, not the labeller. Common ones:

- Is a 3 cm surface depression a pothole or just rough surface?
- Is a crack with crumbling edges a crack or a forming pothole?
- Does a manhole sitting 2 cm proud of the road count as damaged?

**Write the resolved definitions into `data/eval-set/MANIFEST.md` before labelling the
remaining 250 frames.** Ambiguous definitions produce inconsistent labels, and
inconsistent labels put a ceiling on model performance that no amount of training removes.

### The manifest

`data/eval-set/MANIFEST.md` records, for every frame: who labelled it, when, the road,
the weather, the time of day. When a number looks strange in week 9, this is how you
find out why.

---

## Task 2 — Convert RDD2022 to YOLO format

RDD2022 ships in Pascal VOC XML. YOLO wants normalised text.

- Take the **India split only** for now. Establish a clean India baseline before adding
  other countries.
- Map RDD's four classes (`D00` longitudinal, `D10` transverse, `D20` alligator, `D40`
  pothole) onto ours.
- Write it as a script, `scripts/convert_rdd.py`, not as manual steps. We will re-run it.

**Sanity check before training:** render 20 converted images with their boxes drawn on
and look at them. A coordinate-order bug in VOC→YOLO conversion is extremely common,
silently produces boxes in the wrong place, and costs a week if you find it by wondering
why the model will not learn.

---

## Task 3 — Train the baseline

```bash
yolo task=detect mode=train model=yolov8n.pt data=data/rdd_india.yaml epochs=100 imgsz=640
```

Start with **yolov8n** — the smallest. It trains fast, which means fast iteration on the
pipeline. Scaling up is Phase 2's job.

---

## Task 4 — Evaluate honestly

```bash
python scripts/eval_detector.py --set data/eval-set --per-class
```

Report:

- **mAP@50** overall
- **Precision and recall separately, per class**
- A **slice by condition** — dry / wet / shadow / dusk / night

That last one is the useful one. An overall mAP of 0.55 tells you little. "0.72 in dry
daylight, 0.31 on wet roads" tells you exactly what to fix in Phase 2.

---

## What a good result looks like

**A mediocre number.** Genuinely.

For a first baseline, `yolov8n` on RDD India evaluated against your own hand-labelled
local frames, expect something in the region of **mAP@50 of 0.35–0.55**.

**If you get 0.9 on your first run, something is wrong.** In roughly that order of
likelihood:

1. The evaluation set leaked into training (check your file globs)
2. Your eval frames are all easy — same road, same light, same day
3. The conversion script mislabelled everything into one class and the metric is
   measuring something trivial

A suspiciously high first number is a bug report, not a success.

---

## Gate checklist

Phase 1 is done when all of these are true:

- [ ] 200–300 frames labelled in `data/eval-set/`, covering all six conditions
- [ ] `MANIFEST.md` complete, with resolved class definitions
- [ ] Both teammates labelled a shared subset and reconciled disagreements
- [ ] `scripts/convert_rdd.py` runs clean; converted boxes visually verified on 20 images
- [ ] Baseline model trained
- [ ] mAP@50, per-class precision/recall, and per-condition slices written into
      `docs/EVALUATION.md` with the command that produces them
- [ ] `./scripts/verify-claims.sh` passes with the new claims added
- [ ] **Confirmed: zero references to `data/eval-set/` anywhere in the training path**

---

## The trap in this phase

**Everything here is boring and none of it is a model.**

The temptation is to skip the labelling, grab a pretrained pothole model off the
internet, get an impressive-looking demo running in two days, and sort the evaluation out
later.

That path ends in week 11 with a demo that works on one video and a set of numbers nobody
can reproduce — including you.

The held-out set is the thing that makes every later claim true. Build it first, build it
honestly, and never train on it.
