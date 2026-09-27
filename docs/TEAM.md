# Team — who owns what

| | |
|---|---|
| **Atul Chahar** | 251810700198 · [GitHub](https://github.com/Atul-Chahar) · [LinkedIn](https://www.linkedin.com/in/atul-chahar/) |
| **Gyanranjan Panda** | 25100010700022 · [LinkedIn](https://www.linkedin.com/in/gyan-ranjan-080401367/) |

---

## Why this split works

We are genuinely complementary, and it is worth stating plainly because it is the
strongest thing about this team.

**Atul** builds systems end to end and ships them. Founder of EliteFolks (live, launched
on Product Hunt). Won the iQOO Hackathon 2026 Bangalore City Battle with KAVACH, an
on-device AI system. Placed 2nd at the Lyzr Agentathon with a multi-agent decision
system. Previous work in geospatial pipelines (AEGIS), map interfaces (VoldGrid), and
mobile-first offline architecture.

**Gyanranjan** is a backend and scalable-systems engineer. Writes Go and Node.js.
An open source contributor to **Microcks under the CNCF** — meaning he has shipped code
that other people depend on, reviewed by maintainers who did not know him.

Neither of us has trained a detection model end to end before. We are saying that openly
rather than discovering it in week 3. It is the main reason we chose this project.

---

## Ownership

| Layer | Component | Owner | Rationale |
|---|---|---|---|
| L1 | Android capture app | **Atul** | Built AEGIS's offline-first GPS capture already |
| L2 | Detection model | **Both** | The shared learning goal — neither of us has done this |
| L3 | Absence reasoning | **Atul** | Continues from the geospatial work |
| L4 | Geo-fusion and dedup | **Atul** | Directly extends AEGIS's geospatial engines |
| L5 | Ticketing, API, lifecycle | **Gyanranjan** | Backend and scalable systems is his ground |
| L6 | Dashboard | **Gyanranjan** | Pairs naturally with the ticketing API |
| — | Evaluation harness | **Atul** | Porting it from KAVACH |
| — | Documentation | **Both** | Whoever builds it, documents it |

---

## Working agreements

**1. Every phase gate is checked by the person who did not build it.**
If Atul builds the clustering, Gyanranjan runs the gate check. It is too easy to grade
your own work generously.

**2. `data/eval-set/` is sacred.**
Nobody trains on it. Not once, not "just to see". If you find a script that touches it
during training, that is a bug — fix it and say so.

**3. Numbers go in `EVALUATION.md` before they go in a slide.**
If you cannot produce the command that generates a number, the number does not exist yet.

**4. Say when something is not working.**
Phase gates exist so that "this isn't converging" is a normal week-8 sentence, not a
week-12 disaster. The fallbacks in `ABSENCE_DETECTION.md` are declared in advance
precisely so that taking one is a planned move, not a failure.

**5. Documentation is written in plain English.**
Our readers include evaluators and municipal staff. See `GLOSSARY.md`. If you use a
technical word for the first time, explain it or link it.

---

## For any AI agent working in this repo

Read `CLAUDE.md` at the repository root first. It contains the rules, the common
mistakes, and the current state of the project.

Update the "Current state" section of `CLAUDE.md` when you finish a piece of work, so
the next agent — or the other teammate — knows where things stand.
