# Evaluation set manifest

**This data is SACRED. It is never used for training. See `CLAUDE.md` rule 2.**

---

## Agreed class definitions

Fill these in during the two-person labelling check in Phase 1, *before* labelling the
full set. Ambiguous definitions put a ceiling on model performance that no amount of
training can lift.

| Class | Definition | Edge case ruling |
|---|---|---|
| `pothole` | _TBD_ | Minimum depth/width to count? |
| `manhole_ok` | _TBD_ | How proud of the surface is still "ok"? |
| `manhole_damaged` | _TBD_ | Cracked cover vs displaced cover? |
| `manhole_open` | _TBD_ | Partially covered? |
| `crack_longitudinal` | _TBD_ | Minimum length? |
| `crack_transverse` | _TBD_ | |
| `crack_alligator` | _TBD_ | How many interconnected cracks make a pattern? |
| `footpath_broken` | _TBD_ | Does a missing paving slab count? |

---

## Frames

| Batch | Frames | Road / route | Date | Time | Weather | Labelled by | Reconciled |
|---|---|---|---|---|---|---|---|
| _(empty — Phase 1)_ | | | | | | | |

---

## Condition coverage

| Condition | Target | Actual |
|---|---|---|
| Bright daylight, dry | 80 | 0 |
| Overcast / dusk | 50 | 0 |
| Wet road | 40 | 0 |
| Heavy shadow | 40 | 0 |
| Night, headlights | 30 | 0 |
| Fresh tar patches | 20 | 0 |
| **Total** | **260** | **0** |
