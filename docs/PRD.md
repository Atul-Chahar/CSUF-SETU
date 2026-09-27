# PRD — What we are building and why

**Product Requirements Document · SETU · v1.0 · 2026-09-04**

---

## 1. The problem in plain words

Indian city roads are full of problems: potholes, broken or missing manhole covers,
cracked surfaces, footpaths that stop halfway, and junctions where the zebra crossing
has faded to nothing.

Today, a municipal department finds out about these in three ways:

1. **A citizen complains.** Slow, random, and biased towards areas where people know
   how to complain.
2. **A manual survey.** An engineer drives around with a clipboard. Expensive, so it
   happens rarely, so the data is always out of date.
3. **An accident happens.** The worst possible feedback loop.

None of these gives the department a current, complete, ranked picture of which roads
are worst. So repair budgets get spent on the roads that generated the loudest
complaints, not the roads that are most dangerous.

### The official brief

From the CSUF project list, Project No. 4:

> Build a solution to inference the video feeds coming from static CCTV cameras or moving
> cameras (eg. dashcams) to detect all the road infra issues eg. potholes, manholes,
> missing zebra crossing, broken footpath, no footpath zone.
>
> Each road infra issue will be translated into a ticket, which is shared with the
> respective municipal roadinfra department. The department will assign each of these
> tickets to the site engineers/team who will be responsible to address/fix the issue.

Read that carefully. The brief **ends at ticket assignment**, not at detection.
The detection is a means. The ticket is the product.

---

## 2. Who this is for

| User | What they need | How SETU serves them |
|---|---|---|
| **Ward engineer** | A ranked list of what to fix on their roads this week | Ticket queue filtered by ward, sorted by severity |
| **Municipal head** | Proof that money was spent on the worst roads | Map view, SLA tracking, before/after evidence |
| **Site repair crew** | Exact location, photo, and what kind of repair | Ticket with coordinates, image, class and size |
| **Citizen (future)** | Confidence that reported problems get fixed | Public map of open and closed issues |

Our **primary user for this project** is the ward engineer. If the ward engineer would
open the dashboard on a Monday morning and find it useful, we have succeeded.

---

## 3. What success actually means

This is the section we will be judged against, so it is deliberately blunt.

### We have succeeded if:

1. Driving a road once produces a list of its problems, correctly located on a map.
2. Driving the **same road three times produces the same list, not three lists.**
3. A ward engineer can look at the top of the queue and agree those are genuinely the
   worst problems on that road.
4. Every accuracy number we quote can be reproduced by one command by someone who does
   not trust us.

### We have failed if:

1. The model is accurate but the ticket list is full of duplicates.
2. The system reports problems that are not there, and a crew is sent out for nothing.
3. Our numbers only exist in a slide deck.

Note that **failure mode 1 and 2 are both about trust, not accuracy.** A tool a
department stops opening has zero value regardless of its mAP score.

---

## 4. What we are building — scope

### In scope (committed)

| Issue type | Detection method | Confidence |
|---|---|---|
| Pothole | Object detection (YOLO) | High — well-supported by RDD2022 |
| Manhole (damaged / open / missing cover) | Object detection | Medium — needs supplementary data |
| Surface cracks (longitudinal, transverse, alligator) | Object detection | High — RDD2022 covers all three |

Plus the full pipeline: capture app, deduplication, severity scoring, ticket lifecycle,
and dashboard.

### In scope (research stretch, with declared fallback)

| Issue type | Detection method | Fallback if it does not converge |
|---|---|---|
| No-footpath zone | Segmentation + road-segment analysis | Report *footpath coverage %* per segment instead of a yes/no verdict |
| Missing zebra crossing | Segmentation + OpenStreetMap junction priors | Report *junctions lacking visible markings* as candidates for human review |

These two are genuinely hard research problems — see `ABSENCE_DETECTION.md`. We commit
to shipping *something useful* for both, and we state up front which version we shipped.

### Explicitly out of scope

We are saying these clearly so nobody is surprised at the demo.

- **Real integration with a live municipal ITMS.** We will build the ticket format and
  an export, but we have no access to a real department's system.
- **Static CCTV feeds.** The brief mentions them. We are doing dashcams only. CCTV has
  a fixed viewpoint which makes the geospatial problem completely different, and doing
  both properly is not possible in 12 weeks.
- **Automatic repair cost estimation.**
- **Night-time and heavy-rain performance guarantees.** We will augment for these and
  measure them, but we will not promise them.

---

## 5. The core insight

**The model is 30% of the work. Deduplication is the other 70%.**

A dashcam recording at even 5 frames per second sees a pothole in roughly 40 consecutive
frames as the car approaches and passes it. Three drive-throughs produce ~120 detections
of one hole in the ground.

A naive system creates 120 tickets. A ward engineer opens the dashboard, sees 120 tickets
for a road they know has about 15 potholes, concludes the system is broken, and never
opens it again.

So SETU's central function is not "find potholes". It is:

> **Turn many noisy observations into one correct, well-located, trustworthy work order.**

Everything in `DEDUPLICATION.md` follows from this.

---

## 6. The thing nobody else does

Because we merge detections by *location* rather than by *frame*, we get a capability
for free that no municipal system currently has:

**Automatic fix verification.**

Drive the road again next month. If the cluster that used to fire no longer fires, the
pothole is gone. The ticket closes itself, with a before-and-after photo pair as
evidence. The department gets an automatic audit trail proving the repair happened.

This is a genuinely novel contribution and it should be prominent in the presentation.

---

## 7. Constraints we are working within

- **12 weeks**, alongside other coursework.
- **Two people.**
- **No budget** — every dataset, model and tool must be free or open source.
- **No access to a real municipal system.**
- **Consumer hardware** — a phone for capture, a laptop or free Colab GPU for training.

These constraints are the reason for several decisions that would otherwise look odd,
such as starting with server-side inference and porting to the phone last.

---

## 8. Ethical and privacy notes

Dashcam video of public roads captures faces and vehicle number plates.

- We do **not** store raw video beyond the processing step.
- We blur or discard frames that are not needed for a detection.
- Our tickets store the *road defect* crop, not the surrounding scene where avoidable.
- We collect no data about individuals, and we do not identify drivers or pedestrians.

This is worth a slide. Evaluators notice when a team has thought about it, and a real
municipality would ask on day one.
