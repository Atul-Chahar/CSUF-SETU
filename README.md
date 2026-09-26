# SETU — Road Infra Issues Detection System

> **SETU** (सेतु) means *bridge* in Sanskrit. It is the bridge between a road that is
> broken and the engineer whose job it is to fix it.

**Polaris School of Technology · CSUF Capstone 2025–2029 · Project No. 4**

| | |
|---|---|
| **Team** | Atul Chahar (251810700198) · Gyanranjan Panda (25100010700022) |
| **Track** | Computer Vision — Core CV (CNN / Generative Vision) |
| **Status** | Phase 0 — planning and setup |

---

## What are we building, in one paragraph?

You drive down a road with a phone mounted on your windscreen. The phone records
video and its location at the same time. Our software watches that video and finds
things that are wrong with the road — potholes, broken manholes, cracks, missing
footpaths, missing zebra crossings. It then turns each problem into a **ticket**: a
work order that goes to the right municipal department, with a location on a map, a
photo, and a severity rating. A site engineer opens the ticket, fixes the road, and
the next time anyone drives past, our software notices the problem is gone and closes
the ticket by itself.

That last sentence is the part nobody else does.

---

## Why this is harder than it sounds

Most people hear "detect potholes" and think the whole project is training an AI model
to spot a pothole in a picture. That part is real, but it is roughly 30% of the work
and it is the part that is already mostly solved.

The other 70% is this:

**A dashcam sees the same pothole in 40 frames in a row.** Drive the same road again
tomorrow and it sees the same pothole another 40 times. If every single detection
becomes a ticket, the municipal office receives thousands of duplicate tickets in the
first week, decides the system is broken, and stops opening the dashboard. The project
fails — not because the AI was bad, but because nobody thought about what happens after
the AI is right.

So the real problem is: **turn many noisy detections into one clean, trustworthy,
correctly-located work order.** That is what SETU is actually about.

---

## Start here

Read these in order. They are written in plain English on purpose.

| # | Document | What it tells you |
|---|---|---|
| 1 | [docs/PRD.md](docs/PRD.md) | The problem, who has it, and what we are promising to build |
| 2 | [docs/GLOSSARY.md](docs/GLOSSARY.md) | Every technical word in this repo, explained simply |
| 3 | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | The six layers of the system and how data flows through them |
| 4 | [docs/DEDUPLICATION.md](docs/DEDUPLICATION.md) | The core idea: 40 frames → 1 ticket |
| 5 | [docs/ABSENCE_DETECTION.md](docs/ABSENCE_DETECTION.md) | How you detect something that is *missing* |
| 6 | [docs/DATA.md](docs/DATA.md) | Which datasets we use and how to get them |
| 7 | [docs/ROADMAP.md](docs/ROADMAP.md) | 12 weeks, 7 phases, with a measurable gate on each |
| 8 | [docs/PHASE_1.md](docs/PHASE_1.md) | Exactly what to do first |
| 9 | [docs/EVALUATION.md](docs/EVALUATION.md) | Every claim we make, and the command that proves it |
| 10 | [docs/TEAM.md](docs/TEAM.md) | Who owns what |
| 11 | [docs/REPO_AUDIT.md](docs/REPO_AUDIT.md) | Why we did not reuse the public pothole repos |
| 12 | [docs/PITCH.md](docs/PITCH.md) | The presentation script |

---

## The one rule in this repo

**Every number we publish must be reproducible by one command.**

```bash
./scripts/verify-claims.sh
```

If a number appears in this README, in a slide, or in a demo, it also appears in
[docs/EVALUATION.md](docs/EVALUATION.md) next to the exact command that produces it.
If any claim stops being true, the script exits with an error.

We are asking a municipal department to trust an automated system. Trust has to be
checkable, not asserted. This rule is borrowed from
[KAVACH](https://github.com/Atul-Chahar/KAVACH_IQOO), which won the iQOO Hackathon
2026 Bangalore City Battle using exactly this discipline.

---

## Licence

Apache 2.0. See [LICENSE](LICENSE).
