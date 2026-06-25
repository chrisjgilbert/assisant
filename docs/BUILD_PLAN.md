# Chief-of-Staff — Build Plan (v2, for approval)

A personal daily-prioritisation assistant for a product engineer, built on
Karpathy's "LLM Wiki" pattern: **compounding, LLM-maintained synthesis over
immutable raw sources** — not query-time RAG alone.

v2 folds in your answers and your steer to build a **vertical slice** (Slack +
Google Calendar end-to-end) before adding the other connectors.

Status: **DRAFT FOR APPROVAL.** No system code written yet.

---

## 0. Decisions locked (from your answers)

| # | Decision |
|---|---|
| Slack | Pro/Business workspace. Want **private + public channels + DMs**. Pulled via the **Cowork Slack connector** (OAuth; reads everything you can see, incl. private + DMs), kept **read-only**. `slackdump` demoted to a fallback for bulk historical backfill. |
| Granola | Defer to a later phase, but via the **Cowork Granola connector** (not the local cache / a bespoke API). |
| Linear | Defer to a later phase, via the **Cowork Linear connector**. Scope = your work team. |
| All sources | **Everything comes through Cowork connectors.** No bespoke export scripts — ingestion is one generic, source-parameterized **pull skill**. |
| Calendar | **Google Calendar**, via the Cowork Google Calendar connector. |
| Ingestion mechanism | **Cowork connectors fetch → persist immutable raw to `~/sources/` → synthesize.** The connector is the *fetcher into the raw layer*, NOT live-RAG. With every source connector-based and *mutable*, the local raw snapshot pins what each synthesis was derived from at a point in time — the one guardrail keeping this from collapsing into connector-RAG. |
| "Fully local" scope | Storage, embeddings, and the brain stay on-device. Connector content does pass through Claude (inherent to using Claude) — not a local-only data path. |
| Raw location | No preference → using sibling **`~/sources/`** (hard immutability + separate QMD trust level). |
| Privacy | **Fully local**, incl. embeddings (QMD's local EmbeddingGemma). |
| Cadence | **Manual** in Claude Code to start. |
| Delivery | **File only** — a brief markdown file Cowork can present. |
| Backlog/retention | Default: ingest **last ~14 days** on first run; **keep all raw** indefinitely for now. (See Q9 explanation.) |
| Packaging | Package the plugin after the slice proves value. |
| **Scope** | **Vertical slice first: Slack + Google Calendar → synthesis → retrieval → daily brief.** Granola/Linear/drift/lint come after. |

---

## 1. Architecture assessment (unchanged core + slice notes)

**Agree / keep:** raw/brain/schema = Karpathy's raw/wiki/schema; immutable raw +
per-claim provenance is the fix for stale-as-fact; human-owned goals
(propose-never-write); brain outside the repo; prove the loop before automating.

**Key risks, re-ranked for the slice:**

1. **Don't let connectors become live-RAG.** Every source is a Cowork connector,
   which solves access entirely (OAuth, reads as you, no tokens) — but makes the
   *easy* path (live-query everything, synthesize on the fly, store nothing) very
   tempting, and that path quietly deletes the immutable-raw layer along with
   provenance and re-derivation. Because connectors are *systems of record that
   mutate*, the local raw snapshot pins each synthesis to a point in time.
   **Rule: connector fetches → write immutable raw to `~/sources/` → synthesize
   from raw.** Phase 0 verifies read access, read-only.
2. **QMD is RAG; Karpathy says don't lean on query-time RAG.** QMD indexes the
   **brain (synthesis) as primary**, raw as secondary; the brief reads curated
   `index.md` + context pages first, search is the fallback.
3. **Slack is high-volume / low-signal** — which is exactly why pairing it with
   **Calendar** (low-volume, structured) in the slice is smart: calendar grounds
   the brief while Slack synthesis is being tuned.
4. **Brain goes stale** — defend from day one: `source @ date` citations,
   freshness metadata, regenerate-from-raw over hand-patching. Lint is the
   later backstop.
5. **Connector has write tools.** The Slack connector can post messages/create
   channels. Keep it **read-only** for this system (allow read, block
   `send_message`) so a scheduled/automated run can never post on your behalf.

---

## 2. Directory structures & conventions

### `~/brain/` (LLM-owned, outside repo)
```
~/brain/
  CLAUDE.md            # schema/conventions; "goals/ is read-only to ingestion"
  index.md             # catalogue of pages; read FIRST on query (Karpathy)
  log.md               # append-only: ## [2026-06-25] ingest | <title> (Karpathy)
  goals/               # HUMAN-OWNED. company.md team.md personal.md weightings.md
  context/             # LLM-synthesized; every claim cites raw@date
    slack.md           #   rolling Slack context (slice)
    projects/ people/ topics/
  daily/   YYYY-MM-DD.md     # daily log (human / assistant-drafted)
  briefs/  YYYY-MM-DD.md     # generated brief (kept; Cowork presents this file)
  signals/ recalibration.md  # append-only drift flags (human reviews)
```

### `~/sources/` (immutable raw, sibling, outside repo)
```
~/sources/
  slack/     <channel|dm>/YYYY-MM-DD.json (+ rendered .md)   # slice
  calendar/  YYYY-MM-DD.md                                    # slice
  granola/  linear/   # later
```

### This repo (`assisant/`, behaviour/scaffolding)
```
README.md   CLAUDE.md
docs/        BUILD_PLAN.md  ARCHITECTURE.md  SETUP.md
plugin/chief-of-staff/skills/
  pull/  ingest/  onboard/  daily-brief/  query/   # slice (pull = connector→raw)
  drift-detect/  draft-daily-log/  lint/           # later
scripts/
  qmd_setup.*                                      # the only script in the system
config/
  sources.yml                                      # per-connector pull config (channels, windows)
templates/   goal.*  weightings.md  context.page.md  daily.log.md  brief.md
```

Citation convention everywhere:
`> source: slack/eng-team/2026-06-20.json @ 2026-06-20`.

---

## 3. Skill vs sub-agent vs script

*Script = determinism, no LLM. Skill = reusable judgement in the main thread
with you in the loop. Sub-agent = isolation/parallel fan-out, added later only.*

| Component | Type | Why |
|---|---|---|
| QMD index/embed/daemon | **Script** | Deterministic, idempotent, no judgement, no LLM. The only script in the whole system. |
| Connector pull → raw (Slack/GCal/Granola/Linear) | **Skill (one, generic)** | Connector tools are LLM-invoked, not shell-invoked. A single source-parameterized "fetch scoped window → write immutable raw to `~/sources/`" skill, kept read-only. Adding a source = config, not a new script. |
| Onboarding interview | **Skill** | Needs judgement + live dialogue. Never a sub-agent (can't interview you). |
| Ingest → synthesis | **Skill** | Core Karpathy "ingest"; judgement-heavy; you steer takeaways. |
| Daily brief / query | **Skill** | The product; ranked reasoning + answers, filed back as pages. |
| Drift detect / daily-log draft / lint | **Skill (later)** | Judgement + strict write-discipline; lint fans out to **sub-agents per subgraph** at scale. |

Everything ships as a skill first; sub-agents arrive only when fan-out is real.

---

## 4. Phase-by-phase plan (vertical slice)

### Phase 0 — Verify connectors + foundations + prove QMD
- **Goal:** clear the load-bearing unknowns before building anything.
- **Build:**
  - **Connector spike:** confirm the Cowork **Slack** connector can read a
    **private channel + a DM**, and the **Google Calendar** connector can read
    events — read-only — and that we can write what we pull to `~/sources/`.
  - `~/sources/` + `~/brain/` skeletons; `qmd_setup` (two collections, `embed`,
    MCP daemon wired into Claude Code); confirm real MCP tool names.
  - ~15 Slack/calendar-shaped sample files + ~15 benchmark Q/A.
- **DoD:** (a) real private-channel + DM + calendar content lands in
  `~/sources/` via the connectors; (b) QMD returns the right source for ≥80% of
  benchmarks. **If (a) fails → Decision Point 1.**

### Phase 1 — Onboarding interview → goals
- **Goal:** opinionated goals + your real prioritisation judgement (the brief
  needs something to rank against).
- **Build:** `onboard` skill → drafts `goals/{company,team,personal}.md` +
  `weightings.md`; you edit.
- **DoD:** four edited goal files; `weightings.md` encodes concrete trade-offs;
  headers mark them human-owned.

### Phase 2 — Slice ingestion (Slack + Google Calendar)
- **Goal:** real Slack + calendar flowing in, synthesized with provenance, raw
  kept.
- **Build:** a connector-driven **pull skill** (Slack: private+public+DMs,
  scoped channels, last ~14d; GCal: events) that writes immutable raw to
  `~/sources/`; then the `ingest` skill → `context/slack.md` (rolling) +
  relevant context pages, updates `index.md`/`log.md`, cites raw. Calendar is
  mostly structured — fed largely raw into the brief.
- **DoD:** an ingest of real data yields a context page whose every claim cites
  raw; index/log update.

### Phase 3 — Daily brief over the slice  ← **go/no-go**
- **Goal:** a ranked brief you'd act on, grounded in goals + Slack + today's
  calendar.
- **Build:** `daily-brief` skill (reads `index.md` + `context/slack.md` +
  today's calendar + QMD fallback → `briefs/YYYY-MM-DD.md`, a file Cowork can
  present) and `query` skill ("what did I do last week / decide about X / been
  avoiding").
- **DoD:** brief ranks priorities with reasoning, **each citing goal + source**,
  and your edits are minor. **This is the main go/no-go (Decision Point 2).**

### Later phases (after the slice proves out)
- **P4** Add Granola + Linear — now just new entries in `config/sources.yml`
  pointing the generic pull skill at those connectors. Cheap by design.
- **P5** Drift detection → `signals/recalibration.md` (structured, conservative,
  high-signal sources only; never writes goals).
- **P6** Daily-log automation fallback (calendar + Linear + Granola draft).
- **P7** Lint pass (contradictions / stale / orphans / goal-vs-reality;
  subgraph fan-out). Package the plugin around here.

---

## 5. Decision points

1. **End of Phase 0 — Do the connectors read what we need, and is QMD good
   enough?** Fork: (a) proceed with the Slack+Calendar slice; (b) connector
   can't reach private channels/DMs → fall back to `slackdump`, or pivot slice
   to **Calendar + Granola**; (c) QMD weak → swap embedder / lean on the curated
   index.
2. **End of Phase 3 — Is the prioritisation loop actually useful on real
   Slack+calendar?** *(main go/no-go)* Fork: (a) broaden connectors (P4+);
   (b) data's fine but judgement is off → iterate `weightings.md`/brief skill;
   (c) not useful → stop.
3. **Later (after drift + several cycles) — Is compounding synthesis trustworthy
   over time?** Fork: keep compounding / pull back toward query-time retrieval /
   raise lint cadence.

---

## 6. Residual items to confirm before I start Phase 0

1. **Slack slice = Slack + Google Calendar** (my recommendation), or Slack
   only?
2. **Backlog/retention defaults** (last ~14d ingest, keep all raw) — OK?
3. **Connectors enabled?** Confirm the Cowork **Slack** and **Google Calendar**
   connectors are connected in your Claude Desktop. (I won't pull anything until
   you confirm.)
4. **Which Slack channels** (plus DMs/mentions) are in scope for the slice?

Answer these and I'll begin Phase 0.
