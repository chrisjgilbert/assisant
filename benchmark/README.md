# Phase 0 Benchmark — Prove QMD Retrieval

This benchmark validates the load-bearing Phase 0 assumption from
`docs/BUILD_PLAN.md`: **before building synthesis/brief skills, confirm QMD can
return the right source for a question.** If retrieval is weak, the rest of the
system is built on sand.

- **Sample data:** `../samples/` — a self-contained fictional scenario (Northwind,
  the Billing Squad, the UBB pilot, INC-214). `samples/sources/` mirrors
  `~/chief-of-staff/sources/` (immutable raw Slack + calendar); `samples/brain/` mirrors
  `~/chief-of-staff/brain/` (the synthesized layer, primary index target).
- **Questions:** `questions.md` — ~15 Q/A with expected answers and the evidence
  file(s) that must be retrieved.

---

## How to run it

You can point QMD straight at `samples/`, or copy the samples into the real
`~/chief-of-staff/sources` / `~/chief-of-staff/brain` layout. The copy path most closely mirrors how the real
system runs.

### Option A — copy into the real layout (recommended, matches production)

```bash
# from the repo root
cp -R samples/brain/*   ~/chief-of-staff/brain/      # synthesized layer (PRIMARY index)
cp -R samples/sources/* ~/chief-of-staff/sources/    # immutable raw (secondary index)

# build the two QMD collections + embeddings + MCP daemon
scripts/qmd_setup.sh                  # see docs/SETUP.md if this isn't wired yet
```

> Heads up: this writes into `~/chief-of-staff/brain` and `~/chief-of-staff/sources`. If you already have real
> data there, use Option B against a throwaway dir instead.

### Option B — index the samples in place

Point `qmd_setup` (or `qmd embed`) at `samples/brain` (primary) and
`samples/sources` (secondary) without copying. Use this for a clean, disposable
run.

### Then ask each question

For each question in `questions.md`, either:

- run `qmd query "<question>"` directly, or
- use the `query` skill (`plugin/chief-of-staff/skills/query/`) once it exists.

Record, for each: **what came back** and **which source file(s) QMD surfaced**.

---

## How to score it

**Phase 0 Definition of Done:** QMD returns the **correct source** for **≥ 80%**
of the questions (12 of 15).

Scoring rules:

- A question is **PASS** if the top retrieved results include at least one of the
  question's listed evidence files (for multi-source questions, retrieving *any*
  one valid evidence file counts as a retrieval pass; note in "Notes" if it
  missed the others — combining is a synthesis concern, not a retrieval one).
- **Negative controls (Q14, Q15)** are **PASS** if QMD returns nothing relevant
  / low-confidence (no real file is confidently surfaced). They are **FAIL** if
  QMD confidently cites some unrelated sample file as if it answered the question.
- Prefer judging on the **brain** (`context/*`) results since the brain is the
  primary index; raw-file hits also count.

If you score below 80%, see Decision Point 1 in `docs/BUILD_PLAN.md` (swap
embedder / lean harder on the curated `index.md`).

### Scorecard (fill in)

| #   | Question (short)                              | Evidence retrieved? | Correct source? | PASS/FAIL | Notes |
|-----|-----------------------------------------------|---------------------|-----------------|-----------|-------|
| Q1  | UBB rollout decision                          |                     |                 |           |       |
| Q2  | INC-214 root cause                            |                     |                 |           |       |
| Q3  | What I've been avoiding                       |                     |                 |           |       |
| Q4  | What Priya needs from me                      |                     |                 |           |       |
| Q5  | What Marcus needs before roadmap sync         |                     |                 |           |       |
| Q6  | What I did last week                          |                     |                 |           |       |
| Q7  | Is the flag live in staging?                  |                     |                 |           |       |
| Q8  | Backfill design vs runbook ownership          |                     |                 |           |       |
| Q9  | Invoice PDF status                            |                     |                 |           |       |
| Q10 | My open INC-214 action items                  |                     |                 |           |       |
| Q11 | Calendar today + tie to incident (multi)      |                     |                 |           |       |
| Q12 | Top priority this week (multi: goals+slack)   |                     |                 |           |       |
| Q13 | Runbook deadline + why (multi)                |                     |                 |           |       |
| Q14 | Stripe→Adyen migration (NEGATIVE)             |                     |                 |           |       |
| Q15 | Mobile billing rewrite (NEGATIVE)             |                     |                 |           |       |

**Total PASS: ____ / 15.  DoD met (≥ 12)?  ☐ Yes  ☐ No**
