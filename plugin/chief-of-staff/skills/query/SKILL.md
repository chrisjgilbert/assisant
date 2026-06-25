---
name: query
description: Answers arbitrary questions about the user's work over time from the synthesized brain (and raw as backup), with citations — e.g. "what did I do last week?", "what did we decide about X?", "what have I been avoiding?". Use for ad-hoc retrieval/recall questions; optionally files durable answers back as a context page with the user's nod.
---

# query — answer questions about the user's work over time

## Purpose
Answer ad-hoc questions about what the user has done, decided, or been neglecting,
by reading the curated brain FIRST and using QMD search as a fallback, then
synthesizing a cited answer. Distinguish what's well-evidenced from what's
inferred. Optionally compound: when an answer is durable and reusable, offer
(only with the user's agreement) to file it back as a new context topic page.

## Hard guardrails (read first)
- **Read order is load-bearing:** `~/brain/index.md` FIRST, then QMD search of
  the brain (PRIMARY collection), then raw (SECONDARY) only as backup. Do NOT
  jump straight to query-time RAG over raw — lean on the synthesized brain.
- **Read-mostly.** The ONLY thing this skill may write is a new
  `~/brain/context/topics/<topic>.md` page, and ONLY when the user explicitly
  agrees. It may also append a `~/brain/log.md` line when it does so.
- **NEVER write `~/brain/goals/`**, never modify `~/sources/`, never overwrite
  existing context pages (this skill creates new topic pages, it does not patch
  others — that's `ingest`'s job).
- **Cite everything** with the exact form
  `> source: <path under ~/sources> @ <YYYY-MM-DD>`. Separate evidenced claims
  from inferences and label inferences as such.
- **No confabulation.** If the brain + search don't support an answer, say what's
  missing rather than inventing.

## Inputs it reads
- `~/brain/index.md` — the curated catalogue; consult first to find the right
  pages.
- `~/brain/context/*` — synthesis pages (slack.md, projects/, people/, topics/).
- `~/brain/daily/YYYY-MM-DD.md` and `~/brain/briefs/YYYY-MM-DD.md` — for
  "what did I do" / "over time" questions and for tracking unprogressed threads.
- **QMD search (fallback):** the MCP daemon — brain collection PRIMARY, raw
  collection SECONDARY — to retrieve specifics the curated pages don't surface.
- `~/sources/` raw — only when a claim needs to be pinned to its primary source
  for citation.

## Procedure
1. **Read the catalogue.** Read `~/brain/index.md` to locate the pages most
   relevant to the question before searching.
2. **Pull from curated synthesis.** Read the relevant `context/` pages (and
   `daily/` / `briefs/` for time-range or recall questions). Prefer these over
   search.
3. **Search to fill gaps (fallback).** Run QMD search — brain PRIMARY, raw
   SECONDARY — only where the curated brain is insufficient.
4. **For "what have I been avoiding"-type questions,** reason over
   recurring-but-unprogressed threads: scan `context/*`, `daily/`, and recent
   `briefs/` for topics that keep appearing without movement (mentioned across
   multiple dates, flagged as open, never resolved). Surface those, with the
   dates that show the lack of progress.
5. **Synthesize a cited answer.** Lead with the answer. Cite each evidenced claim
   to its raw source. Clearly separate inference from evidence ("Well-evidenced:
   … / Inferred: …"). Note gaps or staleness honestly.
6. **Offer to compound (optional).** If the answer is durable and reusable (not a
   one-off), ASK the user whether to file it back as
   `~/brain/context/topics/<topic>.md` (Karpathy: explorations compound). Only on
   a clear yes:
   - write the page with a context header and citations (see format),
   - and append a `~/brain/log.md` line.
   Do NOT write it unprompted.

## Output (only when the user agrees to compound)

### New topic page — `~/brain/context/topics/<topic>.md`
```markdown
---
title: <Topic> — answer page
category: context
last-synthesized: 2026-06-25
origin: query   # filed from a query answer, with the user's agreement
---

# <Topic>

<synthesized answer, every claim cited>
> source: slack/eng-product/2026-06-20.md @ 2026-06-20

## Open / unresolved
- <anything still inferred or unverified>
```
> Note: after creating a topic page, remind the user it should be re-indexed
> (`scripts/qmd_setup.sh reindex`) and ideally folded into `index.md` by `ingest`.

### Log line — append to `~/brain/log.md` (only when a page was filed)
```markdown
## [2026-06-25] query | filed context/topics/v1-importer-decision.md (user-approved)
```

## Examples
- "What did we decide about the importer?" → read `index.md`, open
  `context/projects/v1-launch.md`, answer with the decision and a Slack
  citation; offer to file `context/topics/v1-importer-decision.md`; on yes,
  write it and log.
- "What have I been avoiding?" → scan `context/slack.md`, recent `daily/` and
  `briefs/`; find a "migrate auth" thread mentioned 06-12, 06-19, 06-24 with no
  progress; report it as a recurring-but-unprogressed thread with those dates;
  label as inferred where it's a judgement call. No file written unless asked.
