# Chief-of-Staff

A personal "chief of staff" assistant for a product engineer. It builds a
**compounding, LLM-maintained synthesis** of your work life — Slack, calendar, and
later more — on top of **immutable raw sources**, and turns it into a ranked daily
brief you can act on. It follows Karpathy's "LLM Wiki" pattern: an LLM continuously
maintains a structured knowledge base ("the brain") that is re-derivable from raw
snapshots, rather than relying on query-time RAG alone.

This repository is **behaviour only** — skills, scripts, templates, docs, and
config templates. Your actual data lives in two directories **outside** this repo:
`~/chief-of-staff/brain/` (the LLM-owned synthesis) and `~/chief-of-staff/sources/` (immutable raw snapshots).

## The three-layer model

The system keeps three layers strictly separate:

```
  ── 1. RAW SOURCES — ~/chief-of-staff/sources/   (immutable, read-only)
        Snapshots pulled from Cowork connectors. Never modified.
        slack/<channel|dm>/YYYY-MM-DD.json (+ .md)   calendar/...
              │  synthesize (cite source @ date)
              ▼
  ── 2. THE BRAIN — ~/chief-of-staff/brain/   (LLM-owned markdown)
        goals/ (HUMAN-OWNED)  context/ (synthesis)  daily/  briefs/
        config/sources.yml  signals/  index.md  log.md  CLAUDE.md
              │  drives / is driven by
              ▼
  ── 3. BEHAVIOUR — this repo (assisant/)   (version-controlled)
        plugin/chief-of-staff/skills/  scripts/  templates/  docs/
```

Layers 1 and 2 live in your home directory, **outside this repo**, and are never
committed. This repo only ships the *behaviour* that operates on them.

## V1 scope

V1 is a deliberate vertical slice: **Slack + Google Calendar**, end to end.

```
  Slack + Google Calendar  →  raw snapshot  →  synthesis  →  retrieval  →  daily brief
```

Calendar (low-volume, structured) grounds the brief while Slack synthesis is being
tuned. Granola, Linear, drift detection, and lint are **later phases** — see
[docs/BUILD_PLAN.md](docs/BUILD_PLAN.md).

## Repo layout

```
assisant/
  README.md                  # this file
  CLAUDE.md                  # guidance for Claude/Cowork sessions in this repo
  LICENSE
  docs/
    BUILD_PLAN.md            # the approved plan & decisions (source of record)
    ARCHITECTURE.md          # canonical architecture explanation
    SETUP.md                 # step-by-step V1 setup on a Mac
    QMD.md                   # how QMD retrieval works (illustrative reference)
  plugin/chief-of-staff/
    skills/
      pull/                  # connector → immutable raw in ~/chief-of-staff/sources/
      ingest/                # raw → synthesis in ~/chief-of-staff/brain/ (cited)
      onboard/               # onboarding interview → drafts goals
      daily-brief/           # ranked brief over goals + slice
      query/                 # ad-hoc questions over the brain
  scripts/
    qmd_setup.sh             # set up QMD (local markdown search + MCP daemon)
    bootstrap_brain.sh       # create ~/chief-of-staff/brain & ~/chief-of-staff/sources, copy templates/config
  config/
    sources.example.yml      # TEMPLATE; real config lives in ~/chief-of-staff/brain/config/
  templates/                 # goal / context / daily / brief markdown templates
  samples/                   # fictional raw + synthesized brain for Phase 0 testing
    sources/                 #   mirrors ~/chief-of-staff/sources/ (raw Slack + calendar)
    brain/                   #   mirrors ~/chief-of-staff/brain/ (synthesized, cited)
  benchmark/                 # 15 Q/A + scorecard to verify QMD retrieval on samples/
```

## Quick start

See **[docs/SETUP.md](docs/SETUP.md)** for the full walkthrough. In short:

1. **Validate retrieval first (Phase 0 gate):** `scripts/bootstrap_brain.sh`, copy
   `samples/` into `~/chief-of-staff/brain` & `~/chief-of-staff/sources`, run `scripts/qmd_setup.sh`, then score
   `benchmark/` (target ≥ 12/15). No connectors needed. If it fails, stop here.
2. Connect the Slack and Google Calendar connectors in Cowork (read-only).
3. Bootstrap the brain: `scripts/bootstrap_brain.sh` (creates `~/chief-of-staff/brain` & `~/chief-of-staff/sources`).
4. Install/index QMD: `scripts/qmd_setup.sh` (run **after** bootstrap — it indexes those dirs).
5. Populate `~/chief-of-staff/brain/config/sources.yml` from `config/sources.example.yml`.
6. Enable the plugin (or symlink skills into `~/.claude/skills/`).
7. Run the onboarding interview once, then run the daily loop.

## How it works — the daily loop

```
  pull  ──▶  ingest  ──▶  daily-brief
   │           │              │
   │           │              └─ reads goals + ~/chief-of-staff/brain/context + today's calendar
   │           │                 (+ QMD fallback) → ~/chief-of-staff/brain/briefs/YYYY-MM-DD.md
   │           └─ synthesizes raw into ~/chief-of-staff/brain/context/*, updates index.md & log.md,
   │              cites every claim as `> source: <path> @ <date>`
   └─ fetches the configured window via Cowork connectors and writes IMMUTABLE
      raw snapshots to ~/chief-of-staff/sources/ (Slack read-only; new channel memberships are
      proposed into ~/chief-of-staff/brain/signals/new-channels.md, never auto-subscribed)
```

Goals are **human-owned**: ingestion may *propose* recalibrations by appending to
`~/chief-of-staff/brain/signals/recalibration.md`, but never writes `~/chief-of-staff/brain/goals/`. The brief is
delivered as a markdown file that Cowork can present.

## Learn more

- [docs/BUILD_PLAN.md](docs/BUILD_PLAN.md) — the approved plan and locked decisions.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — the architecture in depth.
- [docs/SETUP.md](docs/SETUP.md) — getting V1 running on a Mac.
- [docs/QMD.md](docs/QMD.md) — how QMD retrieval works (illustrative reference).
