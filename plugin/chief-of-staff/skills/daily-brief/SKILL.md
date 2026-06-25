---
name: daily-brief
description: Produces the product — a ranked daily prioritisation brief grounded in the human-owned goals/weightings, the synthesized brain, and today's calendar, with every priority cited. Use when the user asks for their daily brief or "what should I focus on (today)".
---

# daily-brief — the ranked daily prioritisation brief

## Purpose
Generate a clean, self-contained markdown brief that tells the user what to focus
on today, **ranked** against their goals and prioritisation weightings, with each
priority backed by WHY (which goal/weighting it serves) and EVIDENCE (a cited raw
source). Read the curated brain FIRST; use QMD search only to fill gaps. Be
honest about staleness and missing data instead of confabulating.

## Hard guardrails (read first)
- **Read order is load-bearing** (curated synthesis first, search as fallback):
  `index.md` → `goals/*` + `weightings.md` → `context/*` (esp. `context/slack.md`)
  → today's calendar raw → **then** QMD search for gaps. Do NOT start with QMD
  search.
- **Writes are confined to:** `~/chief-of-staff/brain/briefs/YYYY-MM-DD.md` and a log line in
  `~/chief-of-staff/brain/log.md`. Nothing else. **NEVER write `~/chief-of-staff/brain/goals/`**,
  `context/`, `index.md`, or `~/chief-of-staff/sources/`.
- **Grounding rule:** a priority with NO goal link AND NO source citation must
  not be ranked highly — list it low and flag it `(unverified)`.
- **Citation form is exact:** `> source: <path under ~/chief-of-staff/sources> @ <YYYY-MM-DD>`.
- **No confabulation.** If `context/slack.md` is stale or calendar raw is
  missing for today, SAY SO in the brief rather than inventing priorities.
- **Regenerate fresh each day.** The brief is rebuilt from current state; old
  briefs are kept for audit, never edited.

## Inputs it reads (in this order)
1. `~/chief-of-staff/brain/index.md` — the curated catalogue of pages + freshness dates. Start
   here to know what synthesis exists and how fresh it is.
2. `~/chief-of-staff/brain/goals/company.md`, `team.md`, `personal.md`, and `weightings.md` —
   what to rank against and the trade-off rules to rank by.
3. `~/chief-of-staff/brain/context/*`, especially `~/chief-of-staff/brain/context/slack.md` (rolling Slack
   synthesis), plus any relevant `context/projects|people|topics/` pages the
   index points to.
4. Today's calendar raw under `~/chief-of-staff/sources/calendar/` (the most recent / today's
   snapshot) — calendar is structured; consume it largely raw.
5. **QMD search (fallback only):** if the curated brain leaves a gap, search the
   QMD MCP daemon — **brain collection first (primary), raw second (secondary)**
   — to retrieve supporting detail. Note in the brief when a priority leans on
   search rather than curated synthesis.

## Procedure
1. **Catalogue.** Read `index.md`; note which context pages exist and their
   `last-synthesized` dates. Flag anything notably stale for the watch-outs
   section.
2. **Load the ranking basis.** Read all `goals/*` and `weightings.md`. The
   ordered work-type ranking and override rules in `weightings.md` ARE the
   ranking function.
3. **Gather signal.** Read `context/slack.md` and index-pointed context pages for
   open threads, decisions, who-needs-what. Read today's calendar raw for
   meetings, deadlines, and time pressure.
4. **Fill gaps (fallback).** Only where the curated brain is thin, run QMD search
   (brain primary, raw secondary) to recover specifics. Keep citations to the raw
   source.
5. **Rank.** Form candidate priorities. Score each by `weightings.md`: which
   work-type is it, do override rules flip it, what's today's time pressure
   (calendar). Apply the grounding rule — anything with neither a goal link nor a
   citation drops to the bottom and is marked `(unverified)`.
6. **Write the brief** to `~/chief-of-staff/brain/briefs/YYYY-MM-DD.md` in the layout below:
   a short "context / what's changed" preamble, the ranked priorities (each:
   one-line action, WHY → goal/weighting, EVIDENCE → cited source), and a
   "watch-outs / open threads" section. Call out staleness/missing data honestly.
7. **Log.** Append one line to `~/chief-of-staff/brain/log.md` (see format).
8. **Hand off.** Tell the user the brief is at `~/chief-of-staff/brain/briefs/YYYY-MM-DD.md` so
   Cowork can present it.

## Output it writes — `~/chief-of-staff/brain/briefs/YYYY-MM-DD.md`
```markdown
---
title: Daily brief
date: 2026-06-25
generated_at: 2026-06-25T09:20:00Z
inputs: [index.md, goals/*, context/slack.md, calendar/2026-06-25.md]
---

# Daily brief — 2026-06-25

## Context / what's changed
2–4 lines: the meaningful shifts since the last brief, and any freshness caveats
(e.g. "context/slack.md last synthesized 06-23 — Slack signal may be 2 days stale").

## Priorities (ranked)
1. **<one-line action>**
   - WHY: serves `goals/team.md` — "ship V1 importer" and ranks high under
     weightings rule #2 (dated external commitment).
   - EVIDENCE:
     > source: slack/eng-product/2026-06-24.md @ 2026-06-24
2. **<one-line action>**
   - WHY: `weightings.md` override — unblock teammate idle today.
   - EVIDENCE:
     > source: calendar/2026-06-25.md @ 2026-06-25
3. **<one-line action>** (unverified)
   - WHY: no goal link / no citation found — surfaced low, confirm before acting.

## Watch-outs / open threads
- Recurring-but-unprogressed thread: <X> (seen 06-18, 06-21, 06-24, no movement).
- Stale / missing data: <what, and why it matters>.
```

### Log line — append to `~/chief-of-staff/brain/log.md`
```markdown
## [2026-06-25] brief | 4 priorities
```

## Example
On 2026-06-25 the user asks "what should I focus on today?". You read `index.md`
(notes `context/slack.md` is from 06-23), then `goals/*` + `weightings.md`, then
`context/slack.md`, then `calendar/2026-06-25.md`. A customer escalation in Slack
maps to weightings rule #1 → ranked first, cited to the Slack raw. A Friday
roadmap commitment ranks second, cited to a project page's source. One vague
"maybe look at the dashboard" idea has no goal/citation → listed last as
`(unverified)`. You note the 2-day Slack staleness in the preamble, write
`~/chief-of-staff/brain/briefs/2026-06-25.md`, and append `## [2026-06-25] brief | 4 priorities`.
