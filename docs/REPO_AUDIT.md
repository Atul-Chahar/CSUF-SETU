# Repo audit — why we are not forking an existing pothole detector

**Date: 2026-09-03 · Decision: build our own pipeline, reuse datasets not code**

Four public pothole-detection repositories were reviewed as candidates for reuse. This
document records what each actually contains and why it was rejected, so nobody
re-litigates this decision in week 6.

---

## Summary

| Repo | Stars | Licence | Verdict |
|---|---|---|---|
| `anantSinghCross/pothole-detection-system-using-convolution-neural-networks` | 82 | MIT | ❌ Reject |
| `noorkhokhar99/Pothole-Detection-...-python-and-deep-learning` | 49 | **NONE** | ❌ Reject — legal |
| `mounishvatti/pothole_detection_yolov8` | 36 | MIT | ⚠️ Salvage one dataset link |
| `devstrons/pothole-detector` | 12 | MIT | ❌ Reject |

---

## 1. anantSinghCross — 82 stars, MIT, last updated 2020

**What the README implies:** a real-time CNN pothole detection system.

**What it actually is:** a Keras binary classifier. It converts each frame to greyscale,
resizes to 300×300, and answers one question: *is there a pothole somewhere in this
image, yes or no.*

**Why we reject it:**

It produces **no bounding boxes**. There is no localisation at all.

That is fatal for us. Our entire pipeline depends on knowing *where in the frame* the
defect is, because that is what lets us project it to a ground position and cluster it
(see `DEDUPLICATION.md`). A yes/no per frame cannot be geo-located, cannot be sized,
cannot be counted, and cannot be deduplicated.

The README itself admits this: *"the model does not tell the number of potholes"* and
suggests YOLO or Mask-RCNN as future work. We would be starting from that future work
anyway.

Also 2019-era TensorFlow/Keras with greyscale preprocessing — we would be inheriting six
year old assumptions.

**Salvageable:** the `My Dataset` folder (214 MB of images) could theoretically be
re-labelled with boxes. Not worth it when RDD2022 exists with 47,420 already-boxed images.

---

## 2. noorkhokhar99 — 49 stars, NO LICENCE, 2023

**What it is:** YOLOv8 training and prediction scripts, with pretrained weights hosted on
an anonymous Google Drive folder.

**Why we reject it — this one is not a judgement call:**

**The repository has no licence file.** Under copyright law the default for unlicensed
work is **all rights reserved**. Nobody may copy, modify, or redistribute it.

This is a graded, publicly published, Apache-2.0 academic project. Using unlicensed code
in it would be a genuine problem, not a technicality — and it is exactly the kind of thing
an evaluator may check.

Two further concerns even setting the licence aside:

- **The weights are on an anonymous Google Drive** with no training provenance. We would
  have no idea what data produced them, under what licence, or whether they are
  reproducible. We cannot make verifiable claims about a model we cannot account for.
- **`requirements.txt` is 33 KB.** That is a `pip freeze` of someone's entire machine,
  not a dependency list. Installing it would pull in hundreds of unrelated packages.

**Salvageable:** nothing.

---

## 3. mounishvatti — 36 stars, MIT, 2024

**What it is:** three Jupyter notebooks. One is 6.6 MB, another 21.8 MB — because the
cell outputs (images) are committed into the notebook files.

**The actual code content**, stripped of outputs:

```python
!pip install ultralytics roboflow
!yolo task=detect mode=train model=yolov8m.pt data={dataset}/data.yaml epochs=N imgsz=640
```

That is the Ultralytics quickstart. There is no custom architecture, no custom loss, no
custom preprocessing, no deployment code.

**Why we reject the code:** there is nothing to reuse. We can type those two lines.

**What we salvage:** the repo links a Roboflow workspace containing a labelled pothole
dataset. **That link is the single genuinely useful thing across all four repos.** It goes
into `DATA.md` as a supplementary source.

---

## 4. devstrons — 12 stars, MIT, abandoned 2022

**What it is:** a Flutter app skeleton that would show pothole locations on Google Maps.

**Why we reject it:** the entire repository is **21 KB**, including the licence file and
the dependency lockfile. There is essentially no implementation. It was abandoned in
April 2022.

We have already built more capable mobile geo-capture than this in AEGIS — offline-first
GPS breadcrumb recording with a local database and BLE mesh relay. Starting from this stub
would be a step backwards.

---

## The common pattern

Strip away the READMEs and all four repos reduce to the same thing:

```python
from ultralytics import YOLO
model = YOLO("yolov8n.pt")
model.train(data="potholes.yaml", epochs=100, imgsz=640)
```

Ultralytics already made pothole detection three lines of code. Forking a repo to obtain
those three lines buys us nothing and costs us someone else's stale assumptions plus, in
one case, a licence problem.

---

## The gap none of them address

**Every one of these four repos detects potholes and only potholes.**

Our brief requires six issue types, two of which — missing zebra crossings and
no-footpath zones — are *absences*. An object detector cannot detect an absence
(see `ABSENCE_DETECTION.md`).

So even a perfect fork would leave a third of the brief untouched, and it would be the
hardest third.

---

## What we reuse instead

Reuse happens at the **data** and **tooling** layer, not the repo layer:

| We reuse | Instead of |
|---|---|
| **RDD2022** — 47,420 labelled Indian-and-other road images | Someone's 2019 greyscale classifier |
| **IDD** — 10,004 pixel-labelled Indian road scenes | Nothing on offer; none of the repos touch segmentation |
| **Ultralytics YOLO** — the actual library | A repo that wraps it in a notebook |
| **KAVACH's own `verify-claims.sh` and eval harness** | Building an evaluation discipline from scratch |

That last row is the biggest saving of all, and it comes from our own previous project.

---

## If someone proposes forking one of these again

Point them at this document. The decision was made with the repos open, the licences
checked, and the file trees inspected — not from ignorance of what was available.
