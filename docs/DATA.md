# Data — what we train on and how to get it

**Labelling road damage by hand is the single most expensive thing we could do.**
A person drawing boxes manages maybe 100 images an hour. We would need tens of thousands.
That is months of work we do not have.

So the whole data strategy is: **use datasets where someone has already done it, for
Indian roads, with our capture method.** Both of the primary datasets below qualify.

---

## 1. RDD2022 — the main detection dataset

**Road Damage Dataset 2022.** Released for the Crowdsensing-based Road Damage Detection
Challenge.

| | |
|---|---|
| **Size** | 47,420 images |
| **Annotations** | 55,000+ marked damage instances |
| **Countries** | India, Japan, Czech Republic, Norway, USA, China |
| **Classes** | longitudinal crack, transverse crack, alligator crack, pothole |
| **Licence** | Open for research use — check terms before any commercial use |
| **Paper** | https://arxiv.org/abs/2209.08538 |
| **Journal** | https://rmets.onlinelibrary.wiley.com/doi/10.1002/gdj3.260 |

### Why this one specifically

The India portion was captured using **smartphones mounted on cars**, at 960×720
resolution (later resized to 720×720 for consistency with Japan and Czech data).

Read that again: *smartphones mounted on cars, on Indian roads*. That is not a rough
approximation of our setup. That **is** our setup. A model trained on this data will see
exactly the kind of images our app produces — same camera class, same mounting angle,
same road surfaces, same lighting.

This is worth far more than a dataset twice its size collected with professional survey
equipment in Europe.

### How we use it

- Start with the **India split only.** Adding other countries may help generalisation
  later, but establishing a clean India baseline comes first.
- Convert annotations to YOLO format (class, x_center, y_center, width, height, all
  normalised 0–1).
- The four RDD classes map onto four of our classes directly. Manholes and broken
  footpaths are **not** in RDD — those need supplementary data (see section 3).

---

## 2. IDD — the India Driving Dataset

**From IIIT Hyderabad.** This is our answer to the footpath and crossing problem.

| | |
|---|---|
| **Size** | 10,004 finely annotated images (2023 revision: ~20,000) |
| **Classes** | 34 (2023 revision: 41), in a 4-level label hierarchy |
| **Source** | 182 drive sequences on Indian roads |
| **Splits** | train 14,027 · val 2,036 · test 4,038 |
| **Type** | Semantic segmentation — every pixel labelled |
| **Access** | Registration required at https://insaan.iiit.ac.in/datasets/ |
| **Paper** | https://arxiv.org/pdf/1811.10200 |

### Why this one specifically

Most segmentation datasets (like Cityscapes) were built in orderly European cities where
a road has a kerb, then a footpath, then buildings. Indian roads are not like that.

IDD was built **for unstructured traffic**. It adds classes that Cityscapes does not
have — most importantly **drivable area beside the road**: the dirt or rubble strip
people walk on when there is no proper footpath.

That class is precisely the thing we need to recognise a "no footpath zone". A European
dataset would label that strip as "road" or "terrain" and we would never see the problem.

The paper also notes that state-of-the-art models score much lower on IDD than on
Cityscapes — Indian roads are genuinely harder. Good to know in advance, and worth
mentioning in the presentation as evidence we picked the right data.

### ⚠️ ACTION REQUIRED IN WEEK 1

**IDD requires registration and approval. This is not instant.**

Submit the access request on **day one of Phase 0**, before we need the data. If it has
not arrived by week 8, switch Phase 5 to the coverage-metric fallback described in
`ABSENCE_DETECTION.md` rather than sitting idle waiting.

This is the single most likely thing to silently derail the schedule.

---

## 3. Roboflow Universe — gap filling

RDD2022 has no manhole class and no footpath-damage class. Roboflow Universe hosts
thousands of community-labelled datasets, including several for manholes and crosswalk
markings.

Quality varies enormously. Rules for using them:

- Check the licence on **every** dataset before downloading.
- Look at a sample of the labels yourself. Community datasets are often sloppy.
- Never let a community dataset into `data/eval-set/`. Our evaluation set is labelled
  by us, on our roads, or it is worthless.

The `mounishvatti` repo we audited links to one such pothole workspace — that link is the
only thing worth taking from any of the four repos we reviewed.

---

## 4. Our own evaluation set — the most important data we have

**`data/eval-set/` — 200–300 frames, hand-labelled by us, from roads we actually drive.**

### Why we must build this ourselves

Public benchmarks tell you how you do on *their* roads. They cannot tell you how you do
on the road outside our college, in September, at 5pm, in the light we actually have.

Only our own held-out set can answer "does this work here?" — and "does this work here?"
is the only question an evaluator or a municipality genuinely cares about.

### The rules

1. **Never train on it.** Not once. Not "just to see". Not accidentally through a
   wildcard glob. Any script that reads `data/eval-set/` during training is a bug and
   should fail loudly.
2. **Label it before training anything.** If you build the test after seeing the model's
   mistakes, you will unconsciously build a test the model passes.
3. **Include the hard cases on purpose.** Wet roads, long shadows, dusk, tar patches,
   heavy traffic occlusion. A test set of easy frames produces a number that means
   nothing.
4. **Two people label independently on a subset**, then compare. Where you disagree, the
   definition is unclear — fix the definition before labelling the rest.

### What to capture

| Condition | Frames | Why |
|---|---|---|
| Bright daylight, dry | ~80 | The baseline case |
| Overcast / dusk | ~50 | Lower contrast, the common failure mode |
| Wet road after rain | ~40 | Reflections are our worst false-positive source |
| Heavy shadow (trees, buildings) | ~40 | Second worst false-positive source |
| Night with headlights | ~30 | We will not promise night performance, but we should measure it |
| Fresh tar patches | ~20 | Looks like a pothole, is actually a repair — a key negative guard |

---

## 5. Directory layout

```
data/
├── eval-set/          ← SACRED. Hand-labelled. Never trained on.
│   ├── images/
│   ├── labels/
│   └── MANIFEST.md    ← who labelled what, when, under what conditions
├── rdd2022/           ← downloaded, gitignored
├── idd/               ← downloaded, gitignored
└── roboflow/          ← downloaded, gitignored
```

Only `eval-set/` is committed to git. Everything else is downloaded by a script, because
these datasets are gigabytes and git is not a file server.

---

## 6. Augmentation

Our capture conditions are worse than most training data. We compensate by artificially
degrading training images:

| Augmentation | Simulates |
|---|---|
| Motion blur | A moving car, especially at speed or in low light |
| Brightness / contrast jitter | Dawn, dusk, overcast, harsh noon |
| Rain and droplet overlay | Wet windscreen |
| Random shadow patches | Trees and buildings |
| Slight rotation | Imperfect phone mounting |
| JPEG compression artefacts | Real phone camera output |

**Do not augment the evaluation set.** It must stay a fixed, honest yardstick.
