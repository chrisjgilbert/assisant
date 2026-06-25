# Architecture

This document explains the architecture of the Chief-of-Staff assistant. The
*decisions* behind it are recorded in [BUILD_PLAN.md](BUILD_PLAN.md); this document
explains the resulting system and why it is shaped the way it is.

The design follows Karpathy's "LLM Wiki" pattern: an LLM continuously maintains a
structured, human-readable knowledge base that is **re-derivable from immutable raw
sources**, rather than answering purely from query-time retrieval. The synthesis
*compounds* over time; the raw layer is the ground truth it can always be rebuilt
from.

---

## 1. The three layers

The system is built from three layers that are kept **strictly separate**. The
separation is the whole point: it is what prevents the synthesis from quietly
becoming stale-as-fact (see §3).

### Layer 1 — Raw sources (`~/sources/`, outside the repo)

Immutable, read-only snapshots of source data, written by the `pull` skill from
Cowork connectors. Once a file lands here it is **never modified**. This is the
analogue of Karpathy's "raw" layer.

```
~/sources/
  slack/     <channel|dm>/YYYY-MM-DD.json (+ rendered .md)
  calendar/  YYYY-MM-DD.md
  granola/  linear/    # later phases
```

Why immutable: connectors are mutable *systems of record* (a Slack channel today is
not the Slack channel of last week). A local snapshot pins each synthesis to a
specific point in time, preserves provenance, and lets any page be re-derived.

### Layer 2 — The brain (`~/brain/`, outside the repo)

LLM-owned markdown: the compounding synthesis plus the human-owned goals it is
ranked against. This is Karpathy's "wiki".

```
~/brain/
  CLAUDE.md            # schema/conventions for work inside the brain
  index.md             # catalogue of pages; read FIRST on query
  log.md               # append-only ingest log
  goals/               # HUMAN-OWNED: company.md team.md personal.md weightings.md
  context/             # LLM-synthesized; every claim cites raw@date
    slack.md           #   rolling Slack context (V1)
    projects/ people/ topics/
  daily/   YYYY-MM-DD.md
  briefs/  YYYY-MM-DD.md
  config/  sources.yml       # the user's populated source/channel selection
  signals/ recalibration.md  # append-only drift flags (human reviews)
           new-channels.md   # append-only channel-discovery queue (human reviews)
```

`goals/` is special: it is **human-owned** and read-only to ingestion.

### Layer 3 — Behaviour (this repo)

The version-controlled skills, scripts, templates, and docs that operate on layers
1 and 2. Contains **no personal data** — only behaviour and templates. See the repo
[README](../README.md) for the layout.

---

## 2. Data flow

```
  ┌─────────────────┐
  │ Cowork connector│  Slack (read-only), Google Calendar
  │  (OAuth, mutable│
  │  system of      │
  │  record)        │
  └────────┬────────┘
           │  pull skill: fetch configured window
           ▼
  ┌─────────────────────────────────────────────┐
  │ RAW SNAPSHOT   ~/sources/   (IMMUTABLE)       │   ← provenance anchor
  │ slack/<chan>/YYYY-MM-DD.json  calendar/...     │
  └────────┬──────────────────────────────────────┘
           │  ingest skill: synthesize, cite source @ date
           ▼
  ┌─────────────────────────────────────────────┐
  │ SYNTHESIS   ~/brain/context/*   index.md  log │   ← compounding "wiki"
  │ goals/ (human-owned) ranked against           │
  └────────┬──────────────────────────────────────┘
           │  qmd_setup.sh: index two collections
           ▼
  ┌─────────────────────────────────────────────┐
  │ QMD INDEX   brain = PRIMARY, raw = SECONDARY  │   ← retrieval / fallback
  └────────┬──────────────────────────────────────┘
           │  daily-brief / query skills
           ▼
  ┌─────────────────────────────────────────────┐
  │ BRIEF  ~/brain/briefs/YYYY-MM-DD.md           │   ← delivered as a file
  │ QUERY answers                                  │
  └───────────────────────────────────────────────┘
```

The critical invariant: **connector → raw → synthesis**. The connector is the
*fetcher into the raw layer*, not a live-query backend. Synthesis always reads from
the raw snapshot, never directly from the live connector.

---

## 3. Why immutable raw + provenance matters

The tempting failure mode — and the one Karpathy's pattern is specifically designed
to avoid — is **stale-as-fact**: the synthesis confidently asserts something that
was true at synthesis time but is no longer true, with no way to tell which claims
are fresh, where they came from, or how to re-derive them.

Two mechanisms defend against this:

1. **Immutable raw snapshots.** Every synthesis is derived from files in
   `~/sources/` that are pinned to a date and never change. Any page can be
   regenerated from raw rather than hand-patched, so drift is correctable by
   re-derivation.
2. **Per-claim provenance.** Every synthesized claim carries
   `> source: <path under ~/sources> @ <YYYY-MM-DD>`. This makes freshness legible
   and makes it possible to audit or rebuild any assertion.

The alternative — letting the Cowork connectors act as live-RAG (query everything,
synthesize on the fly, store nothing) — is easy and seductive precisely because the
connectors solve access so cleanly. But it deletes the raw layer, and with it
provenance and re-derivation. The architecture exists to resist that pull. Phase 0
of the build verifies, before anything else, that we can actually write what we pull
to `~/sources/`.

---

## 4. QMD and its two collections

Retrieval is QMD: local markdown search backed by a local embedder, exposed to
Claude through an MCP daemon. It indexes **two collections**:

- **brain (PRIMARY)** — the synthesis. This is what the assistant searches first
  for meaning and context.
- **raw sources (SECONDARY)** — the immutable snapshots, at a separate trust level,
  for drilling into specifics or verifying provenance.

QMD is RAG, and Karpathy's caution is *don't lean on query-time RAG*. So the order
of operations is: **read the curated `~/brain/index.md` first**, then the relevant
`context/` pages; QMD search is the **fallback**, not the primary path. The curated
index plus compounding synthesis is the product; search backstops it.

Keeping raw at a separate trust level (a sibling directory and a separate
collection) also means the system can reason about "synthesized claim" vs "raw
source material" without conflating them.

### QMD vs navigation-only retrieval (what QMD adds over Karpathy)

Strictly, Karpathy's LLM Wiki has **no QMD-equivalent**. Its retrieval is
*navigation*: the LLM reads the curated `index.md`, then opens the pages it points
to and follows cross-references. The bet is that good synthesis makes finding things
trivial — retrieval is a side-effect of the wiki being well-organized. That works
while the wiki is coherent and small enough to navigate, but its recall is hostage
to the index: anything **not yet synthesized, mis-filed, or un-cross-referenced is
invisible**, and the **raw layer is effectively unsearchable**.

QMD is the search layer we add *underneath* the synthesis layer so navigation
degrades gracefully at scale instead of silently losing recall:

| Concern | Karpathy (navigate only) | With QMD (navigate + search) |
|---|---|---|
| Recall safety net | Misses anything the index omits | Finds mis-filed / un-linked / not-yet-synthesized content |
| Raw layer | Practically unsearchable | Query raw directly; **verify a synthesized claim against its cited source** |
| Scale | LLM loads index + pages into context | One cheap local query narrows candidates first |
| Cost / latency | Whole pages into context | Targeted chunk retrieval |
| Freshness gap | Only ingested content is findable | Can search raw *before* ingestion catches up |

The raw-verification row is the one that matters most here: because QMD also indexes
the immutable raw, we can always check a brain claim against the snapshot it cites —
the concrete defense against confident-but-stale synthesis hardening into "fact."

What QMD explicitly does **not** do: synthesize, cross-reference, resolve
contradictions, or compound. It finds chunks; it does not maintain a worldview. The
**brain is the product; QMD is plumbing.** Karpathy could assume direct filesystem
reading of a small wiki; we run in Claude Code/Cowork over a brain meant to grow for
years, so we add robust retrieval beneath the synthesis — while keeping synthesis
firmly on top (navigation first, search as fallback).

---

## 5. Skill / script / sub-agent taxonomy

The rule of thumb: **Script = determinism, no LLM. Skill = reusable judgement with
the human in the loop. Sub-agent = isolation / parallel fan-out (added later).**

| Component | Type | Why |
|---|---|---|
| QMD index / embed / daemon | **Script** | Deterministic, idempotent, no judgement, no LLM. The only script in the system (`qmd_setup.sh`); `bootstrap_brain.sh` is a setup helper. |
| Connector pull → raw | **Skill** (one, generic) | Connector tools are LLM-invoked. A single source-parameterized "fetch window → write immutable raw" skill, read-only. Adding a source = config, not code. |
| Onboarding interview | **Skill** | Needs live dialogue + judgement; cannot be a sub-agent. |
| Ingest → synthesis | **Skill** | Core "ingest"; judgement-heavy; human steers takeaways. |
| Daily brief / query | **Skill** | The product: ranked reasoning + answers, filed back as pages. |
| Drift detect / daily-log draft / lint | **Skill (later)** | Judgement + strict write-discipline; lint fans out to **sub-agents per subgraph** at scale. |

Everything ships as a skill first; sub-agents arrive only when fan-out is real.

---

## 6. Human-in-the-loop guarantees

The system is built to *propose, not impose*, on everything the human owns:

- **Goals.** `~/brain/goals/` is human-owned and read-only to ingestion. The system
  may only append proposed recalibrations to `~/brain/signals/recalibration.md`;
  the human reviews and edits goals by hand.
- **Channel discovery.** On each pull, the system diffs the channels you are a
  *member* of against `include ∪ ignore` and appends the delta (new memberships) to
  `~/brain/signals/new-channels.md` with context and a suggested disposition. It
  **never auto-subscribes** — you promote each to `include` or `ignore`.
- **Drift.** Drift detection (later phase) is conservative and high-signal, and
  also writes only to `signals/recalibration.md` — never to goals.
- **Slack write safety.** The Slack connector is kept **read-only** (`send_message`
  blocked) so no run, manual or automated, can post on your behalf.
- **Delivery.** The brief is a markdown file the human reads; nothing is sent or
  acted on automatically in V1.

These guarantees, together with immutable raw + provenance, are what make a
*compounding* synthesis trustworthy enough to maintain over time.
