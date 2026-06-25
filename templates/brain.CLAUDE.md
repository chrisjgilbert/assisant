<!--
  This file is copied to ~/brain/CLAUDE.md by the bootstrap script.
  It is the SCHEMA layer (Karpathy layer 3): the operating manual for any
  Claude / Cowork session working ON the brain. It governs the brain ONLY —
  the repo has its own separate CLAUDE.md governing the behaviour/scaffolding.
  Read this in full before reading, writing, or regenerating anything in ~/brain.
-->

# CLAUDE.md — operating manual for the brain (`~/brain/`)

You are operating on a personal "chief of staff" brain built on Karpathy's
LLM-Wiki pattern: **compounding, LLM-maintained synthesis over immutable raw
sources.** Three layers exist; keep them strictly separate:

1. **Raw** — `~/sources/` (OUTSIDE this dir): immutable connector snapshots
   (`slack/`, `calendar/`). Read-only. Nothing edits raw after it lands.
2. **Brain** — `~/brain/` (here): synthesis + human goals (this dir).
3. **Behaviour** — the `assisant/` repo: skills/scripts/templates. Not here.

## Directory map of `~/brain/`

```
CLAUDE.md            # this file — the schema/operating manual
index.md             # catalogue of every page; READ FIRST on any query
log.md               # append-only chronological activity log
goals/               # HUMAN-OWNED: company.md team.md personal.md weightings.md
context/             # LLM-synthesized pages, every claim cited
  slack.md           #   rolling Slack synthesis (V1 slice)
  projects/ people/ topics/
daily/   YYYY-MM-DD.md      # daily logs (DRAFT until human-confirmed)
briefs/  YYYY-MM-DD.md      # generated daily briefs (Cowork presents these)
config/  sources.yml        # YOUR populated source/channel selection (personal data)
signals/ recalibration.md   # append-only goal-drift proposals (human reviews)
         new-channels.md    # append-only channel-discovery queue (human reviews)
```

## Non-negotiable rules

### 1. goals/ is READ-ONLY to ingestion
`goals/{company,team,personal}.md` and `goals/weightings.md` are **HUMAN-OWNED.**
Never write, edit, or "tidy" them from any automated/synthesis flow. If raw
evidence suggests a goal has drifted, **append a proposal** to
`signals/recalibration.md` (see the recalibration entry format). The human reads
it and edits goals by hand. Propose; never write.

### 2. Cite every synthesized claim
Every factual line in a `context/` page (or any synthesis) is followed by:

```
> source: <path under ~/sources> @ <YYYY-MM-DD>
```

e.g. `> source: slack/eng-product/2026-06-20.json @ 2026-06-20`. The path is
relative to `~/sources/`; the date is when that raw was captured. A claim with
no citation does not belong in the brain — drop it or go find its source.

### 3. Channel discovery proposes, never auto-subscribes
When a pull finds channels you're newly a member of, **append** them to
`signals/new-channels.md` with context + a suggested disposition. Never add a
channel to `include` in `config/sources.yml` automatically. The human promotes
each entry by hand. Same propose-don't-write discipline as goals.

### 4. Slack (and all connectors) are READ-ONLY for this system
Never call `send_message` or any connector write tool. This system only reads.

### 5. Retrieval order: index.md first, QMD second
On any query, **read `index.md` first** to find the right curated page, then read
that page. Use QMD search only as a fallback — and when you do, the **brain is
the primary collection, raw is secondary.** Do not jump straight to vector search.

### 6. Freshness & regeneration discipline
Synthesis goes stale because raw connectors mutate. Defend it:
- Every `context/` page carries `last synthesized: <date>` and a source-coverage
  note. Check these before trusting a page.
- When a page is stale or contradicts newer raw, **regenerate it from
  `~/sources/`** — do NOT hand-patch individual claims onto stale synthesis.
  Re-derivation from raw is what keeps provenance honest.
- After regenerating, update the page's `last synthesized` date, update the
  matching row in `index.md`, and append an `ingest` line to `log.md`.

### 7. Append-only files
`log.md`, `signals/recalibration.md`, and `signals/new-channels.md` are
**append-only.** Add new entries at the bottom; never rewrite or delete earlier
ones. They are the audit trail.

## Page formats (see the templates the brain was seeded from)

- **context page** — header (`title`, `category`, `last synthesized`,
  `source coverage`) then sections: Summary, Key facts, Open threads, Decisions;
  every claim cited per rule 2.
- **daily log** (`daily/YYYY-MM-DD.md`) — `status: DRAFT | CONFIRMED`; sections:
  What I did, Decisions, Blockers, Follow-ups.
- **brief** (`briefs/YYYY-MM-DD.md`) — Context/what changed; ranked priorities
  (each: action + why (goal/weighting served) + evidence citation);
  watch-outs / open threads. Skimmable — Cowork presents this file.
- **index.md** — catalogue rows: page | category | summary | last-synthesized,
  grouped by category. Keep current as pages change.
- **log.md** — `## [YYYY-MM-DD] <verb> | <description>` (verbs: pull, ingest,
  brief, query).
- **recalibration / new-channels entries** — append one block per the entry
  templates; both carry a `status: unreviewed` the human updates.

## Standard workflow on a run

1. Read `index.md` (and this file) before doing anything.
2. If pulling: connector → write immutable raw to `~/sources/` → then synthesize
   from raw. Append discovered memberships to `signals/new-channels.md`.
3. If synthesizing: derive from raw, cite every claim, update the page's
   freshness, update `index.md`, append to `log.md`.
4. Never touch `goals/`; route any drift to `signals/recalibration.md`.
