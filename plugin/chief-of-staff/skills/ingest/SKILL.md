---
name: ingest
description: Fold new immutable raw under ~/chief-of-staff/sources/ into the brain (~/chief-of-staff/brain/) as compounding LLM-maintained synthesis — Karpathy's "ingest" op. Use after a pull to synthesize fresh Slack/calendar raw into cited context pages and update the index/log. Treats ~/chief-of-staff/sources/ as read-only and never writes goals.
---

# ingest — synthesize raw into the brain

## Purpose
Fold newly-pulled raw from `~/chief-of-staff/sources/` into the **brain** at `~/chief-of-staff/brain/` as
compounding, LLM-maintained synthesis. Every synthesized claim carries a
provenance citation back to its raw source, and pages prefer being
**regenerated from raw** over hand-patched so the brain never drifts into
stale-as-fact. Goals are HUMAN-OWNED — ingestion may only *propose* drift.

## Hard guardrails (read first)
- **Writes are confined to:** `~/chief-of-staff/brain/context/**`, `~/chief-of-staff/brain/index.md`,
  `~/chief-of-staff/brain/log.md`, and `~/chief-of-staff/brain/signals/recalibration.md`. Nothing else.
- **`~/chief-of-staff/sources/` is READ-ONLY.** Never modify, delete, or add raw.
- **NEVER write `~/chief-of-staff/brain/goals/`.** If a source implies goals shifted, append a
  proposal to `signals/recalibration.md` only.
- **Every synthesized claim cites raw** with the exact form
  `> source: <path under ~/chief-of-staff/sources> @ <YYYY-MM-DD>`. An uncited claim is a bug.
- **Prefer regenerate-from-raw over hand-patching** when underlying sources
  changed, to defend against stale facts surviving as truth.

## Inputs it reads
- New / unsynthesized raw under `~/chief-of-staff/sources/` (Slack snapshots, calendar
  snapshots).
- `~/chief-of-staff/brain/log.md` and `~/chief-of-staff/brain/index.md` — to know what has already been
  ingested and which pages exist (so you only fold new raw and update the right
  pages).
- Existing `~/chief-of-staff/brain/context/` pages — to update them (regenerating changed
  sections from raw).

## Procedure
1. **Find new raw.** Cross-reference `~/chief-of-staff/sources/` against the `pull`/`ingest`
   entries in `~/chief-of-staff/brain/log.md` and the freshness metadata in pages /
   `index.md`. Select raw snapshots not yet folded in.
2. **Read the brain catalogue first.** Read `~/chief-of-staff/brain/index.md` to learn existing
   pages and their categories before deciding what to update vs. create.
3. **Synthesize rolling Slack context.** Update `~/chief-of-staff/brain/context/slack.md` —
   recent themes, decisions, open threads, and who-needs-what. When the
   underlying raw for a section changed, **regenerate that section from raw**
   rather than editing in place. Cite every claim.
4. **Create/update entity pages when warranted.** When a project, person, or
   topic recurs with enough signal, create/update a page under
   `~/chief-of-staff/brain/context/projects/`, `~/chief-of-staff/brain/context/people/`, or
   `~/chief-of-staff/brain/context/topics/`. Calendar raw is mostly structured — fold it
   lightly; the daily-brief skill consumes calendar largely raw.
5. **Stamp freshness.** Each context page header carries a
   `last-synthesized: YYYY-MM-DD` field (plus title/category). Update it on every
   touch.
6. **Update the index.** Update `~/chief-of-staff/brain/index.md` so each page has: page path,
   category, one-line summary, and freshness date.
7. **Goal-drift check.** If a high-signal source implies the user's goals may
   have shifted, append a conservative, structured proposal to
   `~/chief-of-staff/brain/signals/recalibration.md` (see format). Do NOT touch `goals/`.
8. **Log.** Append one line to `~/chief-of-staff/brain/log.md` (see format).
9. **Re-index reminder.** Tell the user QMD should be re-indexed so new/updated
   pages are searchable: run `scripts/qmd_setup.sh reindex`.

## Outputs it writes

### Context page header (every page under `context/`)
```markdown
---
title: Slack — rolling context
category: context
last-synthesized: 2026-06-25
---
```

### Cited claim format (everywhere in context)
```markdown
The eng team decided to cut the legacy importer for V1.
> source: slack/eng-product/2026-06-20.md @ 2026-06-20
```

### Index entry — `~/chief-of-staff/brain/index.md`
```markdown
| context/slack.md | context | Recent eng themes, decisions, open threads | 2026-06-25 |
```

### Goal-drift proposal — append to `~/chief-of-staff/brain/signals/recalibration.md`
```markdown
- date: 2026-06-25
  source: slack/eng-product/2026-06-20.md @ 2026-06-20
  relates_to: goals/team.md — "ship V1 importer this quarter"
  proposed_delta: "Importer appears descoped from V1; consider moving to next quarter."
  confidence: medium
```

### Log line — append to `~/chief-of-staff/brain/log.md`
```markdown
## [2026-06-25] ingest | folded slack/eng-product 06-20..06-25 + calendar; touched context/slack.md, context/projects/v1-launch.md, index.md
```

## Example
After a pull on 2026-06-25:
- New raw: `slack/eng-product/2026-06-25.md`, `calendar/2026-06-25.md`.
- Read `index.md`; regenerate the "open threads" section of `context/slack.md`
  from the new raw, each claim cited; bump `last-synthesized: 2026-06-25`.
- A recurring "V1 launch" topic warrants `context/projects/v1-launch.md`.
- One message implies a goal descope → append a `medium`-confidence proposal to
  `signals/recalibration.md` (no edit to `goals/`).
- Update `index.md` rows; append the ingest log line; remind the user to run
  `scripts/qmd_setup.sh reindex`.
