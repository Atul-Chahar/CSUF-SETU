# Absence detection — finding what is NOT there

**The hardest and most original part of SETU.**

---

## 1. The problem statement hides a trap

Our brief asks for six issue types:

- potholes ✅
- manholes ✅
- broken footpath ✅
- cracks ✅
- **missing zebra crossing** ❌
- **no footpath zone** ❌

The first four are **objects**. They exist in the world, they have edges, and you can
draw a box around them. An object detector handles them.

The last two are **absences**. They are defined by something *not* being there.

**You cannot draw a bounding box around a zebra crossing that does not exist.**

This is not a detail. It means an object detector — the entire approach every public
pothole repo takes — is structurally incapable of solving a third of our brief.

---

## 2. Why adding a class to YOLO does not work

The tempting shortcut is to add a `missing_crossing` class and train on examples.

It fails, for a reason worth understanding:

**Every frame without a zebra crossing would be a positive example.** A photo of a
motorway with no crossing, a photo of a car park, a photo of a field. The model would
learn "no stripes on the ground = missing crossing" and fire constantly, everywhere.

The missing thing only matters **somewhere it should have been**. A zebra crossing is
not missing on a motorway. It is missing at a junction next to a school.

**An absence is only meaningful against an expectation.** And that expectation cannot
come from the image, because the image is exactly what is lacking the evidence. It has
to come from outside.

---

## 3. Where the expectation comes from: OpenStreetMap

OpenStreetMap is a free, open map of the world. It knows:

- where roads are, and their type (motorway, residential, service road)
- where roads intersect — that is, **where junctions are**
- what is nearby — schools, markets, hospitals, bus stops

That is the outside knowledge we need. OSM tells us *where a crossing ought to exist*.
Our camera tells us *whether one does*. The gap between those two is the issue.

```
   OSM road graph              Our segmentation model
   "junction here"      +      "no crossing markings"     =    ISSUE
   "expectation"               "observation"                   "the gap"
```

---

## 4. Method for missing zebra crossings

1. **Find candidate locations.** Query OSM for road intersections along the surveyed
   route. Filter to junctions where a crossing is genuinely expected — residential and
   arterial roads, especially within ~200 m of a school, hospital, market or bus stop.
   Skip motorway junctions and service lanes.

2. **Find the approach zone.** For each candidate junction, work out which video frames
   were captured while approaching it, in the ~15 metres before the intersection. That
   is where a crossing would be painted.

3. **Look for markings.** Run the segmentation model over those frames and check for
   the road-marking class in that zone. Zebra stripes are high-contrast, regular, and
   perpendicular to travel — a fairly distinctive pattern.

4. **Judge.**
   - Markings clearly present → fine, no issue.
   - Markings faint or partial → **faded crossing** issue (this one is genuinely
     valuable and often more actionable than a fully missing one).
   - No markings at all → **missing crossing** issue, flagged for human confirmation.

**Note step 4's third branch says "flagged for human confirmation", not "ticket raised".**
We should be honest that absence detection is less certain than pothole detection, and
route it through a person before it reaches a repair crew.

---

## 5. Method for no-footpath zones

Different shape of problem, different method.

1. **Segment each frame** into road / footpath / other, using a model trained on IDD.
   IDD matters here specifically because it was built for **unstructured Indian roads**
   and includes classes that European datasets like Cityscapes do not — such as the
   drivable dirt strip beside the road where there is no proper footpath at all. That is
   exactly the situation we need to recognise.

2. **Per frame, ask a simple question:** is there footpath pixel coverage on the left?
   On the right? Record a yes/no for each side.

3. **Look at runs, not frames.** One frame with no footpath means nothing — it could be
   a driveway, a bus stop, or a parked lorry blocking the view. What matters is a
   **continuous run**: 50+ consecutive frames, covering 100+ metres, all with no footpath
   on the same side.

4. **Emit a segment issue.** The output is not a pin on a map. It is:

   > *"Left side of MG Road between these two coordinates — 380 metres with no footpath."*

---

## 6. This changes the data model

**Point issues** (pothole, manhole, crack) have one latitude and longitude.

**Segment issues** (no footpath, and possibly broken footpath) have a start point, an end
point, a length, and a side of the road.

They need different database tables, different map rendering (a pin versus a coloured
line), different severity formulas (a pothole's severity uses size; a footpath gap's uses
length × pedestrian demand), and different ticket text.

**Decide this in Phase 0, before writing any storage code.** Modelling everything as a
point and patching segments in later is a rewrite, and we do not have time for a rewrite
in week 10.

---

## 7. The honest fallback

Absence detection is a research problem. It might not converge in the one week Phase 5
allocates to it. So we declare the fallback **now**, in advance, rather than
improvising under pressure:

| Ideal version | Fallback version |
|---|---|
| "This junction is **missing** its zebra crossing" | "These junctions have **no visible markings** — review list, ranked by pedestrian risk" |
| "This 380 m stretch **has no footpath**" | "Footpath coverage on this stretch is **12%**" — a continuous metric per road segment |

**The fallback is still genuinely useful to a municipality.** A ranked list of
low-footpath-coverage streets is a real planning tool. It is honest, it is achievable,
and it is far better than a half-finished binary classifier that is wrong 40% of the time.

**Phase 5's gate is: ship one of these two properly. Not both, badly.**

---

## 8. Why this is worth the effort

Three reasons to keep this in scope rather than quietly dropping it:

1. **It is in the brief.** Two of the six named issue types are absences.
2. **Nobody else will do it.** Every other team, and every public repo, will train a
   pothole detector. This is where the distance opens up.
3. **It is real research.** Reasoning about expectation versus observation, combining a
   map prior with a vision model — that is a genuine contribution, not a training run.

It is also the part of the project that most clearly demonstrates thinking rather than
tool use, which is exactly what a capstone is meant to show.
