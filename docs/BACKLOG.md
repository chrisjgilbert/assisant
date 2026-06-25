# Post-V1 Backlog

Ideas deferred until the **V1 vertical slice** (Slack + Google Calendar →
synthesis → daily brief) is validated and proven useful. Nothing here is built
yet. The approved phased roadmap (Granola/Linear connectors, drift detection,
daily-log automation, lint) lives in [BUILD_PLAN.md](BUILD_PLAN.md) §4 "Later
phases"; this file captures *additional* ideas raised after V1 was scaffolded.

---

## Meeting prep — per-meeting briefings

**Idea:** for each real meeting on today's calendar, produce a short briefing
grounded in the brain, so you walk into every meeting prepared.

**What each briefing contains**
- **Who** — attendees mapped to `context/people/*`: recent history, what they owe
  you / you owe them (from DMs + `signals/recalibration.md`).
- **What** — the meeting's topic mapped to `context/projects|topics/*` +
  `context/slack.md`: latest decisions, open threads, current state.
- **Why it matters to you** — tied to `goals/` + `weightings.md`.
- **Prep** — suggested questions, decisions to land, relevant things you've been
  avoiding.
- Every claim cited (`> source: … @ date`); QMD as the recall fallback for
  attendees/topics with no brain page yet.

**How it fits the architecture**
- A new **`meeting-prep` skill**, **read-only over the brain** (like
  `daily-brief` and `query`) — synthesizes nothing permanent, only writes the
  briefing file. No new ingestion, connector, or guardrail surface.
- Reuses existing people/project pages, slack context, goals, and the citation
  convention.
- **Output:** one consolidated `~/chief-of-staff/brain/briefs/YYYY-MM-DD-meetings.md` (a section
  per meeting) — one file for Cowork to present.
- **Where in the loop:** last step of the morning routine —
  `pull → ingest → daily-brief → meeting-prep`. The daily brief can end with a
  pointer to the meeting briefs.
- **Skips** declined meetings, focus blocks, and solo holds (configurable).

**Decided design choices**
- Standalone skill + separate meetings file (NOT folded into the daily brief —
  keeps `daily-brief` focused on prioritisation).

**Forward hook (depends on the later Granola phase)**
- For recurring meetings, pull the *previous* meeting's Granola notes/transcript:
  "last time in this 1:1 you agreed X; open action items were Y." Design the skill
  so this slots in cleanly when Granola lands.

**Why deferred:** purely additive and low-risk, but it leans entirely on the
brain being good — so validate V1 retrieval + daily-brief first.

---

## Parked retrieval enhancements

Raised and consciously deferred during the V1 design discussion.

- **Harden the retrieval protocol.** Current skills treat QMD as a soft
  "fallback," which relies on the model *noticing* it didn't find something
  (unreliable). Stronger protocol: index-first, then an **always-run verify
  search** (especially over `~/chief-of-staff/sources/`), plus a **no-citation-no-answer** rule
  (if it can't cite, it must search; if search is empty, say "not in the data").
  Touches `query/SKILL.md`, `daily-brief/SKILL.md`, and `brain.CLAUDE.md`.
- **Surface retrieval method in output.** Today citations show provenance (the
  source path) but not *how* it was found. Optionally tag each citation —
  `(synthesis)` vs `(raw via search)` — so it's obvious when an answer leaned on
  the less-vetted search fallback over raw.
- **Make QMD optional for V1.** A navigation-first path (read `index.md` + grep)
  that works with no QMD daemon running, so the prioritisation loop can be
  validated before standing up embeddings/the MCP server. QMD becomes an
  opt-in optimization once recall starts to hurt at scale.

---

## See also

- [BUILD_PLAN.md](BUILD_PLAN.md) — approved plan; §4 "Later phases" covers
  Granola + Linear connectors, drift detection → recalibration, daily-log
  automation, and the lint pass.
