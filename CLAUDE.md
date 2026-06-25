# CLAUDE.md — guidance for sessions working IN this repo

This file is for any Claude / Cowork session operating inside the
`assisant/` repository. Read it before making changes.

## What this repo is

This repo is **BEHAVIOUR ONLY**: skills, scripts, templates, docs, and config
*templates*. It is version-controlled and may be pushed to GitHub.

**Data does NOT live here.** It lives in two directories outside the repo:

- `~/brain/` — LLM-owned markdown synthesis (the "brain"): `goals/`, `context/`,
  `daily/`, `briefs/`, `config/sources.yml`, `signals/`, `index.md`, `log.md`,
  `CLAUDE.md`. The `~/brain/CLAUDE.md` governs work *inside the brain* and is
  distinct from this file.
- `~/sources/` — immutable raw snapshots pulled from Cowork connectors
  (`slack/`, `calendar/`).

Never commit personal data into this repo. The populated `sources.yml` lives in
`~/brain/config/`; this repo ships only `config/sources.example.yml`.

## The three layers (keep strictly separate)

1. **Raw sources** (`~/sources/`) — immutable, read-only. Connectors write here;
   nothing edits these after they land.
2. **The brain** (`~/brain/`) — LLM-owned synthesis derived from raw, with
   `goals/` being human-owned.
3. **Behaviour** (this repo) — the skills/scripts/templates that operate on 1 → 2.

## Non-negotiable rules

- **Never write `~/brain/goals/` from ingestion.** Goals are HUMAN-OWNED.
  Ingestion may only *propose* changes by appending to
  `~/brain/signals/recalibration.md`. The human reviews and edits goals.
- **Always snapshot raw before synthesis.** Connectors fetch → write immutable
  raw to `~/sources/` → synthesize from raw. Connectors are mutable systems of
  record; the local snapshot pins each synthesis to a point in time and preserves
  provenance + re-derivation. Connectors are NOT live-RAG.
- **Cite every synthesized claim** with `> source: <path under ~/sources> @ <YYYY-MM-DD>`.
- **Slack connector is READ-ONLY.** Never call `send_message` or any write tool.
- **Channel discovery proposes, never auto-subscribes.** New memberships go to
  `~/brain/signals/new-channels.md` for human review — never auto-added to
  `include`.
- **Retrieval = QMD.** Read `~/brain/index.md` first (curated catalogue); QMD
  search (brain primary, raw secondary) is the fallback, not the first move.

## Skills (under `plugin/chief-of-staff/skills/`)

V1 vertical slice (Slack + Google Calendar):

- **pull/** — one generic, source-parameterized skill. Reads
  `~/brain/config/sources.yml`, fetches the configured window via Cowork
  connectors, and writes immutable raw to `~/sources/`. Appends new channel
  memberships to `signals/new-channels.md`. Read-only against connectors.
- **ingest/** — synthesizes raw from `~/sources/` into `~/brain/context/*`,
  updates `index.md` and `log.md`, and cites every claim. May append to
  `signals/recalibration.md`; never writes `goals/`.
- **onboard/** — one-time onboarding interview that drafts
  `goals/{company,team,personal}.md` + `weightings.md` for the human to edit.
- **daily-brief/** — produces a ranked brief over goals + `context/slack.md` +
  today's calendar (QMD fallback) into `~/brain/briefs/YYYY-MM-DD.md`, a file
  Cowork can present.
- **query/** — answers ad-hoc questions over the brain ("what did I decide about
  X", "what have I been avoiding").

Later (not V1): `drift-detect/`, `draft-daily-log/`, `lint/`.

## Operational notes

- Scripts are the only non-LLM, deterministic pieces: `scripts/qmd_setup.sh`
  (QMD + MCP daemon) and `scripts/bootstrap_brain.sh` (create dirs, copy
  templates/config).
- V1 cadence is **manual**. Delivery is a markdown **file** only.
- See `docs/ARCHITECTURE.md` for the why, `docs/BUILD_PLAN.md` for decisions, and
  `docs/SETUP.md` for setup. Do not edit `docs/BUILD_PLAN.md`.
