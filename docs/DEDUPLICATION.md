# Deduplication — turning 40 frames into 1 ticket

**This is the most important document in the repository.**

If you only understand one technical idea in SETU, make it this one. It is what
separates our project from a pothole-detection demo.

---

## 1. The problem

A car drives at 30 km/h. That is about 8 metres per second. Our app records 5 frames
per second. A pothole is visible from roughly 25 metres away until the car passes it.

```
25 metres visible  ÷  8 metres/second  =  ~3 seconds
3 seconds  ×  5 frames/second  =  ~15-40 frames of the same pothole
```

Now drive that road three times over a month, which is exactly what a real survey
programme would do:

```
40 frames  ×  3 passes  =  ~120 detections
```

**Of one hole in the ground.**

A naive system creates 120 tickets. The ward engineer opens the dashboard on Monday
morning, sees 120 tickets for a road they personally know has about 15 potholes, decides
the software is broken, and closes the tab forever.

The model was *right every single time*. The project still failed.

---

## 2. Why you cannot solve this the easy way

Some obvious ideas that do not work:

**"Just take one frame per second."**
Reduces the count but does not fix it. You still get 3 detections per pass instead of 40,
and you now miss potholes that were only visible briefly.

**"Only keep the detection with the highest confidence."**
Highest confidence in which frame? You need to know which detections belong to the same
pothole before you can pick the best one. That is the problem itself.

**"Track the object across frames with a tracker."**
This helps *within* one pass. It does nothing across passes on different days, and it
breaks whenever the pothole leaves the frame and comes back.

**The only thing that identifies a pothole across time, cameras and drivers is its
position on Earth.** So the merge has to happen in geographic space, not image space.

---

## 3. The solution, in three steps

### Step 1 — Ground projection

We know these things:

| Known | From |
|---|---|
| Camera height above the road | Setup calibration screen |
| Camera pitch (downward angle) | Setup calibration screen |
| Camera field of view | Phone specs |
| Where the box sits in the frame | The model |
| Where the car was | GPS |
| Which way the car was facing | GPS heading |

From the vertical position of the **bottom edge** of the bounding box, we can estimate
how far ahead of the car the defect lies. Simple trigonometry: a defect low in the frame
is close, one high in the frame is far.

Then we take the GPS position, move forward along the heading by that distance, and
offset sideways for its horizontal position in the frame. That gives an approximate real
latitude and longitude for the defect.

> **It is approximate, and that is fine.** We are not surveying property boundaries.
> We need to be right to within a few metres, which is enough to know it is the same
> pothole.

### Step 2 — DBSCAN clustering

Now we have thousands of (latitude, longitude, class) points. We cluster them.

**DBSCAN** is the right tool because you do not have to tell it how many clusters to
expect — which is good, because we have no idea how many potholes a road has. You only
tell it one thing: **how close two points must be to count as the same thing.** That
distance is called **epsilon**.

We also constrain it by class: a pothole detection can never merge with a manhole
detection, even if they are 2 metres apart. They are different problems needing
different repairs.

```
19 raw detections across 3 passes
        ↓  DBSCAN, eps = 6m, class-constrained
3 clusters  →  3 issues  →  3 tickets
```

### Step 3 — The count becomes the confidence

This is the elegant part. **We do not throw the duplicates away — we count them.**

| Observations | Interpretation |
|---|---|
| 1 detection, 1 pass | Candidate. Might be a shadow. Do not raise a ticket yet. |
| 5 detections, 1 pass | Probably real, but only one camera has seen it. |
| 8 detections, 3 separate passes | Certain. Three independent drives agree. |

So the 120 detections that would have been 120 tickets become **1 ticket with a
confidence of "seen 120 times across 3 passes"** — which is far more useful information
than either extreme.

---

## 4. The trap: epsilon versus GPS error

**Read this before tuning anything.**

A normal phone's GPS is accurate to about **±5 metres**. That means the *same pothole*,
measured on two different days, might be recorded 8 metres apart purely from GPS noise.

- If epsilon is **too small** (say 3 m), one real pothole splits into three clusters →
  three tickets → the exact duplicate problem we set out to solve.
- If epsilon is **too large** (say 25 m), three genuinely separate potholes on the same
  stretch merge into one → we under-report, and the repair crew arrives to find three
  holes when the ticket described one.

**Epsilon must be larger than the GPS error, but smaller than the typical spacing
between distinct defects.** For Indian city roads that window is roughly **6–8 metres**.

**How to actually set it:** do not guess. Drive one road five times. Count the potholes
by hand. Then sweep epsilon from 2 m to 20 m and plot the resulting ticket count against
your hand count. Pick the value where they match. Record that experiment in
`EVALUATION.md`.

---

## 5. The metric that matters

Model accuracy is not our headline number. **Duplicate rate is.**

```
duplicate_rate = (tickets_created / real_distinct_problems) − 1
```

| Value | Meaning |
|---|---|
| 0.0 | Perfect. One ticket per real problem. |
| 2.0 | We created 3 tickets per problem. Unusable. |
| −0.5 | We merged too aggressively and missed half the problems. |

**Phase 4's gate is a measured duplicate rate published in `EVALUATION.md`.** Not a model
accuracy score. This is the number that decides whether a department keeps using SETU.

---

## 6. The free bonus: automatic fix verification

Because issues are identified by **location** rather than by frame, something useful
falls out for free.

Drive the road again next month:

- The cluster at that location **fires again** → the pothole is still there. Update the
  ticket, note it is overdue, escalate.
- The cluster at that location **does not fire** → the pothole is gone. The repair
  happened.

The ticket can then move itself to **Fix Verified**, attaching the old photo and the new
photo as before-and-after evidence.

**No municipal system does this today.** Today, "was it actually fixed?" is answered by a
contractor's word, or by another site visit. SETU answers it automatically, with photos,
as a side effect of normal surveying.

This should be a prominent slide in the presentation. It is the clearest example of the
project being about a *system*, not a *model*.

---

## 7. Implementation notes for whoever writes this

- Keep the clustering code **pure** — it takes a list of points and returns a list of
  clusters. No database calls, no file reads. That makes it unit-testable in
  milliseconds, which is what lets `verify-claims.sh` check the duplicate rate on every
  commit.
- Use `scikit-learn`'s `DBSCAN` with `metric='haversine'` so distances are true
  great-circle metres, not degrees. Remember to convert coordinates to radians first —
  forgetting this is the classic bug here and produces silently nonsensical clusters.
- Store every raw detection, even after merging. When we later want to re-tune epsilon,
  we must be able to re-cluster from the original data rather than re-driving the road.
