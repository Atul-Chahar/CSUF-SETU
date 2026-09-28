# Architecture — how SETU works, layer by layer

Six layers. Data flows down. Each layer has one job and can be tested on its own.

```
        ┌──────────────────────────────────────────────────────┐
  L1    │  CAPTURE — Android app on the windscreen             │
        │  keyframes @2-5fps + GPS + heading + accelerometer   │
        └──────────────────────────┬───────────────────────────┘
                                   │  frames + telemetry
              ┌────────────────────┴────────────────────┐
              ▼                                         ▼
  ┌───────────────────────────┐        ┌────────────────────────────────┐
  │ L2  DETECTION             │        │ L3  ABSENCE REASONING          │
  │ things that ARE there     │        │ things that are NOT there      │
  │ YOLO → boxes              │        │ segmentation + OSM priors      │
  │ pothole, manhole, crack   │        │ missing footpath / crossing    │
  └─────────────┬─────────────┘        └────────────────┬───────────────┘
                │  per-frame detections                 │  per-segment findings
                └───────────────────┬───────────────────┘
                                    ▼
        ┌──────────────────────────────────────────────────────┐
  L4    │  GEO-FUSION — the heart of the system                │
        │  ground projection → DBSCAN clustering → OSM snap    │
        │  MANY detections  →  ONE issue                       │
        └──────────────────────────┬───────────────────────────┘
                                   ▼
        ┌──────────────────────────────────────────────────────┐
  L5    │  SEVERITY & TICKETING                                │
        │  score − negative guards → 6-state lifecycle → route │
        └──────────────────────────┬───────────────────────────┘
                                   ▼
        ┌──────────────────────────────────────────────────────┐
  L6    │  DASHBOARD — MapLibre + OpenStreetMap                │
        │  ward queue · severity map · before/after evidence   │
        └──────────────────────────────────────────────────────┘
```

---

## L1 — Capture

**Owner: Atul · Android, Kotlin, Jetpack Compose**

A phone clamped to the windscreen. It records three things at once and keeps them
aligned in time.

### What it records

| Signal | Rate | Why |
|---|---|---|
| Video keyframes | 2–5 per second | 30 fps is wasteful — the car has barely moved between frames |
| GPS: lat, lon, heading, speed, accuracy | 1 per second | Tells us where each frame was taken and which way we were facing |
| Accelerometer (Z axis) | 50 Hz | A pothole strike is a vertical jolt |
| Camera calibration | once, at setup | Mount height and pitch angle — without these, ground projection is impossible |

### Why the accelerometer matters more than it looks

This is one of our best ideas and it costs nothing.

When a car wheel drops into a pothole, the phone jolts vertically. That jolt is
**completely independent of the camera**. A shadow on the road, a dark tar patch, or a
wet reflection can all fool a vision model — but none of them shake the car.

So we get a second, cheap, independent confirmation channel. If the camera says
"pothole" *and* the car jolted 0.4 seconds later (the time for the wheel to reach where
the camera was looking), our confidence goes way up. If the camera says "pothole" and
the ride was perfectly smooth, that detection is probably a shadow.

### Offline-first

Roads worth surveying are often roads with no mobile signal. The app writes everything
to a local database first and uploads when a connection appears. This design is lifted
directly from AEGIS, which had to work in Meghalaya with no signal at all.

---

## L2 — Detection (things that ARE there)

**Owner: both · Python, Ultralytics YOLO**

A YOLO model fine-tuned on RDD2022's India split. It draws a box around each defect it
finds and labels it.

### Classes

- `pothole`
- `manhole_ok` / `manhole_damaged` / `manhole_open`
- `crack_longitudinal` — running along the road
- `crack_transverse` — running across the road
- `crack_alligator` — the cracked-mud pattern that means the road base is failing
- `footpath_broken` — a footpath that exists but is damaged

### Deployment order

1. **Server-side batch first.** Upload the drive, process it on a laptop or free Colab
   GPU. Simpler, faster to iterate, lets us focus on accuracy.
2. **On-device later** (Phase 7). Convert to TFLite or NCNN and run on the phone.

We do it in this order deliberately. Trying to optimise for a phone before the model is
even accurate is a classic way to waste six weeks. KAVACH was built the same way.

---

## L3 — Absence reasoning (things that are NOT there)

**Owner: Atul · segmentation + OpenStreetMap**

This layer answers a fundamentally different kind of question, and it needs a
fundamentally different approach. Full detail in `ABSENCE_DETECTION.md`.

Short version: a segmentation model colours every pixel (road / footpath / marking /
other). Then OpenStreetMap supplies the **expectation** — "there is a junction here, so
there should be a crossing" or "this is a residential street, so there should be a
footpath". We compare what we saw against what should be there.

**Key consequence:** absence findings are about *stretches of road*, not points.
"No footpath" is 400 metres, not a pin on a map. Layer 4 and layer 5 must handle both
shapes.

---

## L4 — Geo-fusion (the heart)

**Owner: Atul · Python, scikit-learn, GeoPandas**

Three steps. Full detail in `DEDUPLICATION.md`.

### Step 1 — Ground projection
Convert "a box at pixel (x, y) in this frame" into "a point at this latitude and
longitude in the real world", using the camera's mount height, its pitch angle, the
GPS fix, and the direction of travel.

### Step 2 — Clustering
Run DBSCAN over all projected points, constrained so that only detections of the *same
class* can merge. Epsilon (the "how close counts as the same thing" distance) is about
6–8 metres.

**One cluster becomes one issue.** The number of detections in the cluster becomes the
issue's confidence score — a pothole seen 8 times across 3 separate drives is real; one
seen once is a candidate.

### Step 3 — OSM snapping
Attach each issue to the nearest OpenStreetMap road segment. Now every problem lives on
a named road in a named ward, which is what makes routing to a department possible.

---

## L5 — Severity and ticketing

**Owner: Gyanranjan · backend services**

### Severity score

```
severity = (estimated_area × road_class_weight × observation_count × jolt_magnitude)
           − negative_guards
```

- **estimated_area** — how big is it, from the box size and distance
- **road_class_weight** — a pothole on an arterial road matters more than on a back lane
- **observation_count** — seen more times = more certain
- **jolt_magnitude** — accelerometer spike, our depth proxy
- **negative_guards** — see below

### Negative guards

Rules that *subtract* confidence when a detection matches a known false-alarm pattern:

- a wet patch reflecting the sky
- a fresh tar repair (dark, pothole-shaped, but actually a fix)
- a hard shadow from a building or tree
- a correctly seated manhole cover, flush with the road

This is copied directly from KAVACH, which used 40 such guards to reach a 0%
false-positive rate. It is the single most effective anti-false-positive technique we
know, and it is just a list of rules — no extra model needed.

### Lifecycle

```
New → Verified → Assigned → In Progress → Resolved → Fix Verified
```

Six states, the same shape as AEGIS's rescue lifecycle. The last state is the
interesting one: **it can be entered automatically.** When a later drive-through shows
the cluster no longer firing, the system verifies the fix itself.

---

## L6 — Dashboard

**Owner: Gyanranjan · MapLibre GL + OpenStreetMap**

- Map of all issues, clustered, coloured by severity
- Ticket queue filtered by ward, sorted by severity
- Before/after image pairs from repeat drives
- SLA tracking — which tickets are overdue

We have built this exact map layer before in VoldGrid, so it is a known quantity.

---

## Testing philosophy

Borrowed from KAVACH: **domain logic stays pure.**

The geospatial clustering, the severity scoring and the lifecycle state machine must all
be testable with:

- no phone
- no network
- no GPU
- no real GPS

They are just functions over data. Keeping them that way means we can run the whole
decision layer in unit tests in under a second, which is what makes
`scripts/verify-claims.sh` possible.
