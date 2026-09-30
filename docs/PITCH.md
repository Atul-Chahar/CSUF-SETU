# Pitch — the presentation script

**SETU · Road Infra Issues Detection System · Project No. 4**
Atul Chahar & Gyanranjan Panda

Built for ~8 minutes with time for questions. Cut slides 7 and 8 first if you are short.

---

## The one sentence to have ready

If someone stops you in the corridor and asks what you are building:

> "Everyone thinks this project is about detecting potholes. It isn't. Detection is
> solved. The real problem is that one pothole generates forty detections, and if you
> send forty tickets to a municipal office, they stop opening your dashboard. We are
> building the part that turns forty detections into one work order — and then checks
> next month whether it actually got fixed."

---

## Slide 1 — Open with the trap, not the solution

**Say this:**

> "A dashcam driving at 30 km/h sees a pothole in about forty consecutive frames.
> Drive that road three times in a month and you have one hundred and twenty detections.
>
> Of one hole in the ground.
>
> If you turn each of those into a ticket, the ward engineer opens the dashboard on
> Monday morning, sees a hundred and twenty tickets on a road they know has fifteen
> potholes, decides the software is broken, and never opens it again.
>
> And here is the uncomfortable part — the AI was right every single time. The model
> was perfect. The project still failed."

**Why open here:** every other team will open with "potholes are a problem in India."
You open by demonstrating you understand the problem *behind* the problem. It reframes
the whole project before anyone has formed an expectation.

---

## Slide 2 — The problem, briefly

Do not spend long here. Everyone in the room already knows Indian roads have potholes.

- Municipal departments find out about road defects three ways: a citizen complains, a
  manual clipboard survey, or an accident happens.
- All three are slow, incomplete, and biased toward whoever complains loudest.
- So repair budgets go to the loudest roads, not the most dangerous ones.

**One line to land:** *"They are not short of potholes. They are short of a current,
ranked, trustworthy list."*

---

## Slide 3 — What SETU actually is

> "A phone on the windscreen. It records video, location, and the accelerometer.
> Our system finds the defects, works out where each one is in the real world, merges
> the duplicates, ranks them by severity, and produces a work order for the right
> department — with a map pin, a photo, and a size."

Show the six-layer diagram from `ARCHITECTURE.md`. Do not read it out — point at L4 and
say *"that layer is the project."*

---

## Slide 4 — The core idea, with the diagram

**This is your most important slide. Slow down.**

Show the deduplication diagram: 19 scattered detections above, 3 clean pins below.

> "The only thing that identifies a pothole across three different drives on three
> different days is its position on Earth. So we don't merge in image space, we merge in
> geographic space.
>
> We project each detection to real coordinates, then cluster. One cluster is one issue.
>
> And we don't throw the duplicates away — we count them. A defect seen eight times
> across three independent passes is certain. One seen once is a candidate. The
> duplication becomes the confidence score."

**The number to quote:** *"Our headline metric is not model accuracy. It's duplicate
rate. One real pothole, driven past three times, must produce exactly one ticket."*

---

## Slide 5 — The bit nobody else has

> "Because we identify issues by location rather than by frame, we get something for
> free that no municipal system does today.
>
> Drive the road again next month. If the cluster no longer fires, the pothole is gone.
> The ticket closes itself — with a before photo and an after photo as evidence.
>
> Right now, 'was it actually fixed?' is answered by a contractor's word or another site
> visit. We answer it automatically, with photographs, as a side effect of normal
> surveying."

**Expect this to be the moment the room leans in.** It is the clearest demonstration that
you designed a system rather than trained a model.

---

## Slide 6 — The hard problem we did not dodge

> "Our brief lists six issue types. Two of them are missing zebra crossings and
> no-footpath zones.
>
> You cannot draw a bounding box around a zebra crossing that does not exist. An object
> detector fires when something is *present*. It has no opinion about what should have
> been there and wasn't.
>
> So absence needs an expectation from outside the image. We take it from OpenStreetMap —
> the map knows where the junctions are. The map says a crossing should be here; the
> camera says there isn't one; the gap between them is the issue."

**Then be honest, on the slide:**

> "This is a research problem and it may not fully converge in twelve weeks. So we have
> declared our fallback in advance: instead of a yes/no verdict, we report footpath
> coverage percentage per road segment. Still a real planning tool for a municipality.
> We would rather ship one honest thing than two broken ones."

**Why say this out loud:** volunteering a limitation before anyone finds it is the single
most credibility-building move available in a project review. It also pre-empts the
hardest question in the room.

---

## Slide 7 — Why we can actually build this

Keep this short and factual. No adjectives.

- **AEGIS** — an emergency response system with GPS breadcrumbs, geospatial engines, and
  a six-state incident lifecycle routing to responders. *That is this project's
  architecture with the labels changed.*
- **KAVACH** — won the iQOO Hackathon 2026 Bangalore City Battle. A two-tier on-device
  detection system with 40 negative guards producing a 0% false-positive rate, and a
  `verify-claims.sh` script that checks 31 claims in one minute.
- **Gyanranjan** — Go and Node backend, open source contributor to Microcks under CNCF.

**Then the honest line:**

> "Neither of us has trained a detection model end to end before. That is the main reason
> we picked this project."

---

## Slide 8 — How we will prove it works

> "One command. `./scripts/verify-claims.sh`.
>
> Every number we publish — in the README, in this presentation, in the demo — appears in
> our evaluation file next to the exact command that produces it. If any claim stops
> being true, the script fails.
>
> We are asking a municipal department to trust an automated system. Trust has to be
> checkable, not asserted."

Mention that the harness is already committed in week one, **before there is anything to
verify** — that is deliberate, so that every claim made for the next twelve weeks has to
survive it.

---

## Close

> "Every team on this project will train a YOLO model on potholes, and several will get a
> good score. That is not where the distance is.
>
> The distance is in whether a ward engineer still has the dashboard open in month three.
> That is a deduplication problem, a trust problem, and a verification problem — and
> those are the three things we are building."

---

## Questions you will be asked — prepare these

**"Why not just use an existing pothole detection repo?"**
> We audited four. One has no licence at all, which legally means all rights reserved —
> unusable in a published academic project. One is a whole-frame classifier with no
> bounding boxes, so it cannot locate anything. One is a 21 KB abandoned stub. The last
> is three notebooks wrapping three lines of the Ultralytics API. All four detect
> potholes only, so none of them touch a third of our brief. It's written up in
> `docs/REPO_AUDIT.md`.

**"Where does your training data come from?"**
> RDD2022 — 47,420 images, 55,000 annotated damage instances. Critically, its India split
> was captured with smartphones mounted on cars. That is not an approximation of our
> setup, it *is* our setup. Plus IDD from IIIT Hyderabad for segmentation, which has
> classes European datasets lack — like the drivable dirt beside the road where there is
> no proper footpath.

**"How accurate is your model?"**
> We don't have that number yet, and we won't quote one until it's measured on a held-out
> set we have never trained on. That set gets labelled in Phase 1. When we have the
> number, it goes in `EVALUATION.md` with the command that reproduces it.
>
> *(Do not invent a number. "We don't know yet, here's when we will" is a strong answer
> at a planning review. A made-up number that later moves is fatal.)*

**"What if GPS isn't accurate enough?"**
> That's the sharpest question here. Phone GPS is about ±5 metres, and our clustering
> distance is 6–8 metres, so the margin is genuinely tight. We're not guessing it — we
> drive one road five times, count the potholes by hand, sweep the clustering distance
> from 2 to 20 metres, and pick where the counts match. That experiment is Phase 4's gate.

**"Why the accelerometer?"**
> A pothole strike is a vertical jolt, and it's completely independent of the camera.
> A shadow, a wet reflection, or a tar patch can all fool a vision model — but none of
> them shake the car. It's a free second confirmation channel.

**"Is this actually deployable?"**
> Not to a real municipal system — we have no access to one, and we say so in the PRD.
> We build the ticket format and an export. Everything up to the department's front door
> is real; crossing that threshold needs a partner we don't have.

**"What's your biggest risk?"**
> Scope. Six issue types across twelve weeks with two people is a lot. Our plan is to
> take pothole, manhole and cracks to production quality, and treat the two absence
> types as a research stretch with the declared fallback. Three classes that work beat
> six that nearly do.

---

## Practical notes

- **Have `docs/DEDUPLICATION.md` open in a tab.** If anyone digs into the clustering,
  showing the written reasoning is more convincing than explaining it from memory.
- **The repo itself is a slide.** A clean structure with twelve documents on day one
  says something no claim about "planning" can.
- **Do not oversell the demo.** Nothing is built. This is a design review. Saying
  "nothing is built yet, here is exactly what we will build and how we will prove it"
  is a strong position — it is what a real engineering review looks like.
- **Fix Verified is your money slide.** If you only get one idea across, make it that one.
