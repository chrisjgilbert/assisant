# Chief-of-Staff — Build Plan (v1, for review)

A personal daily-prioritisation assistant for a product engineer, built on
Karpathy's "LLM Wiki" pattern: **compounding, LLM-maintained synthesis over
immutable raw sources** — not query-time RAG alone.

Status: **DRAFT FOR APPROVAL.** No system code is written yet. Open questions
are at the end; answer those and we lock the plan.

---

## 1. Assessment of the architecture

### Where I agree (keep these)

- **Three layers map cleanly onto Karpathy's three layers.** Your
  raw/brain/schema split is exactly his raw-sources / wiki / schema. Good.
- **Immutable raw + provenance is the single most important principle.** It is
  the direct fix for the failure mode his commenters hit: confident-but-stale
  synthesis hardening into "fact." Every synthesized claim must cite the raw
  source + date it came from. Non-negotiable.
- **Goals are human-owned; ingestion proposes, never writes.** Correct, and
  the right answer to "what happens when an All Hands transcript implies my
  priorities changed."
- **Brain (data) lives outside this repo.** Right call — data and behaviour
  must version independently and have different privacy profiles.
- **Don't over-engineer; prove the loop before automating.** Agreed, and it
  shapes the whole phase order below. Sub-agents/scheduling are Phase 5+.

### Where I'd push back or add nuance

1. **QMD is RAG, and Karpathy's whole thesis is "don't rely on query-time
   RAG."** There's a real tension here that the design has to resolve
   deliberately, or you'll quietly rebuild RAG and lose the compounding
   benefit. Resolution: **QMD indexes the *brain* (synthesized pages) as the
   primary collection and the *raw sources* as a secondary collection.** The
   daily brief reads the curated `index.md` + synthesized context pages
   *first*; QMD search is the fallback for the long tail and for verifying a
   synthesized claim against raw. If you find yourself answering everything via
   `qmd search` over raw, the synthesis layer isn't earning its keep — that's a
   signal, not the intended steady state.

2. **Drift detection is the highest false-positive-risk component.** Inferring
   "your goals may have drifted" from a transcript is fuzzy classification. The
   risk isn't a wrong rewrite (we forbid writes) — it's *noise*: the
   recalibration file fills with weak signals, you stop reading it, and the
   feature is dead. Mitigation: make every flag **structured and conservative**
   (cite source + the specific goal line + proposed delta + a confidence), only
   run it on high-signal sources (All Hands, planning docs — not every Slack
   message), and review it in a *ritual*, not on every ingest.

3. **The brain itself will go stale — plan for it from day one, not at Phase
   6.** This is the same trap Karpathy's commenters described. Defenses baked
   in early: (a) every synthesized line cites `source#id @ date`; (b) freshness
   metadata on each context page; (c) **prefer regenerating a page from raw
   over hand-patching synthesis** when a source changes; (d) lint (Phase 6) is
   the backstop, not the primary defense.

4. **There is no clean unified connector — each source is a bespoke adapter,
   and Slack is genuinely constrained.** From research:
   - **Granola:** no official API. Community tools read the *local cache*
     (`~/Library/...`) and export markdown + transcripts with mic-vs-system
     diarization (`theantichris/granola`, `wassimk/granary`,
     `magarcia/granola-cli`). Workable, local, but unofficial.
   - **Linear:** clean GraphQL API + CLIs (`schpet/linear-cli`,
     `linear-export`) → markdown/JSON. Easiest source.
   - **Slack:** the hard one. Official export of **private channels + DMs**
     requires Business+/Enterprise admin or the Discovery API. On Free/Pro you
     can only self-serve public channels. The practical path is a **user-token
     tool** (`rusq/slackdump`, `sebseager/slack-exporter`) with an `xoxp`
     token — works without admin but depends on your workspace's policy.
   So ingestion is **N independent adapter scripts that dump into `~/sources/`**,
   each decoupled from the brain. Don't design a "connector framework"; design
   three small scripts.

5. **The daily-log fallback needs a calendar source you haven't listed.**
   "Draft from calendar + Linear + Granola" requires calendar access (macOS
   Calendar or Google Calendar). That's a 4th adapter. Flagged as an open
   question.

6. **One naming caveat to verify in Phase 0:** the docs I found expose QMD's
   MCP tools as `query` / `get` / `multi_get` / `status` (HTTP daemon on
   `localhost:8181`), while you referenced `qmd_search`. Minor, but we confirm
   the actual tool names against the running server in Phase 0 rather than
   hard-coding the wrong one into skills.

**Net:** the architecture is sound. The two things most likely to sink it are
(a) treating QMD as the primary brain instead of the synthesis layer, and
(b) drift-detection noise. Both are addressed above.

---

## 2. Directory structures & file conventions

### 2a. `~/brain/` — the synthesis layer (LLM-owned, OUTSIDE this repo)

```
~/brain/
  CLAUDE.md            # the schema/conventions: how the brain is organised &
                       # maintained, page formats, citation rules, "goals are
                       # read-only to ingestion." (Karpathy's Layer 3, local copy)
  index.md             # content catalogue of every page, by category, 1-line
                       # summaries + freshness. Read FIRST on any query. (Karpathy)
  log.md               # append-only chronological log:
                       #   ## [2026-06-25] ingest | <source title>
                       # one line per ingest/synthesis/flag. (Karpathy)
  goals/               # HUMAN-OWNED. Ingestion never writes here.
    company.md
    team.md
    personal.md
    weightings.md      # the actual prioritisation judgement / trade-off rules
  context/             # LLM-synthesized pages. Every claim cites raw source+date.
    projects/<slug>.md
    people/<slug>.md
    topics/<slug>.md
    slack.md           # rolling Slack context summary
  daily/
    YYYY-MM-DD.md      # the daily log (human-edited, or assistant-drafted)
  briefs/
    YYYY-MM-DD.md      # generated daily brief output (kept, so it compounds &
                       # is auditable against later reality)
  signals/
    recalibration.md   # append-only proposed goal changes / drift flags.
                       # Human reviews; promoting a flag into goals/ is manual.
```

### 2b. `~/sources/` — raw sources (immutable, sibling of brain, OUTSIDE repo)

```
~/sources/
  granola/   YYYY-MM-DD--<meeting>.md      (notes + transcript, YAML frontmatter)
  linear/    <TEAM>-<n>.md  or  dump-YYYY-MM-DD.json
  slack/     <channel>/YYYY-MM-DD.json     (+ rendered .md)
  calendar/  YYYY-MM-DD.md                 (if calendar adapter added)
```

**Deviation from your spec, flagged for approval:** I'd put raw in a *sibling*
`~/sources/` rather than `~/brain/raw/`. Reasons: (1) hard immutability — the
brain dir is "LLM writes here," the sources dir is "LLM only reads here," and
separating them makes that boundary obvious and enforceable; (2) QMD indexes
them as **two collections** with different trust levels (synthesis vs ground
truth). If you'd rather keep one tree, `~/brain/raw/` works too — just a
convention call.

### 2c. This repo (`assisant/`) — behaviour/skills/scaffolding (version-controlled)

```
assisant/
  README.md
  CLAUDE.md                 # repo-level: "this repo is BEHAVIOUR; data lives in
                            # ~/brain and ~/sources; here's how they connect"
  docs/
    BUILD_PLAN.md           # this file
    ARCHITECTURE.md         # the 3-layer model + data-flow diagram
    SETUP.md                # install QMD, wire MCP, run adapters, point at ~/brain
  plugin/
    chief-of-staff/         # eventual plugin package (manifest + skills)
      plugin.json
      skills/
        onboard/SKILL.md
        ingest/SKILL.md
        daily-brief/SKILL.md
        query/SKILL.md
        drift-detect/SKILL.md
        draft-daily-log/SKILL.md
        lint/SKILL.md
  scripts/                  # deterministic adapters (no LLM)
    ingest_granola.*        # community tool wrapper → ~/sources/granola/
    ingest_linear.*         # linear-cli/API → ~/sources/linear/
    ingest_slack.*          # slackdump (xoxp) → ~/sources/slack/
    ingest_calendar.*       # (optional) → ~/sources/calendar/
    qmd_setup.*             # index.yml, embed, daemon up/down
  templates/                # seed formats for brain pages
    goal.company.md  goal.team.md  goal.personal.md  weightings.md
    context.page.md  daily.log.md  brief.md  recalibration.entry.md
```

**Citation convention (used everywhere in the brain):**
`> source: granola/2026-06-20--roadmap-sync.md @ 2026-06-20` appended to any
synthesized claim, so provenance and freshness travel with the text.

---

## 3. Skill vs sub-agent vs script — and why

The deciding question for each piece: *does it need judgement, isolation, or
just determinism?*

| Component | Type | Why |
|---|---|---|
| Granola / Linear / Slack / Calendar export | **Script** | Pure deterministic data movement, must be cheap, idempotent, reliable, and runnable without an LLM. Writes only to `~/sources/`. |
| QMD index/embed/daemon control | **Script** | Same — mechanical, no judgement. |
| Onboarding interview | **Skill** | Needs judgement *and* live back-and-forth with you. Must be main-thread; explicitly NOT a sub-agent (a sub-agent can't interview you). |
| Ingest → synthesis (read raw, update context pages + index + log) | **Skill** | Judgement-heavy; this is the core Karpathy "ingest" op. Main-thread so you can steer takeaways. |
| Daily brief / prioritisation | **Skill** | The product. Reads goals + synthesis + search, produces ranked reasoning. Main-thread. |
| Query ("what did I do last week / decide about X / avoid") | **Skill** | Karpathy "query" op; answers can be filed back as pages. |
| Drift detection | **Skill** | Judgement + strict write-discipline (append to `signals/` only). |
| Daily-log drafting | **Skill** | Judgement over calendar+Linear+Granola; you edit the result. |
| Lint | **Skill now, sub-agent fan-out later** | Karpathy "lint" op. Starts as a single pass; at scale his commenters note full-wiki lint is too expensive → fan out **one sub-agent per subgraph** (e.g. per `context/projects/*`). First clear sub-agent use. |
| Batch ingest of a large backlog | **sub-agent (later)** | Parallel, context-heavy, read-mostly fan-out — one agent per source file keeps the main thread clean. Only after the single-file loop works. |

**Principle:** *Script = determinism, no LLM. Skill = reusable judgement in the
main thread with you in the loop. Sub-agent = isolation/parallelism for heavy or
fan-out work, added only as a proven optimisation.* Per your own "don't
over-engineer" rule, everything ships as a Skill first; sub-agents arrive in
Phase 6 and only where fan-out is real.

---

## 4. Phase-by-phase plan

Each phase has a **Definition of Done (DoD)** — don't advance until it's met.

### Phase 0 — Prove QMD retrieval is good enough
- **Goal:** validate the load-bearing assumption before building anything on it.
- **Build:** `~/sources/` + `~/brain/` skeletons; ~15–20 *hand-written*
  representative samples (fake meetings, Linear issues, Slack snippets, a draft
  goals file); `qmd_setup` (`index.yml` with two collections, `qmd embed`, MCP
  daemon wired into Claude Code); a fixed set of ~15 benchmark questions with
  expected answers. Confirm the real MCP tool names.
- **Files/skills:** `scripts/qmd_setup.*`, sample data, `docs/SETUP.md`.
- **DoD:** retrieval returns the right source for ≥80% of benchmark questions,
  including a "what did we decide about X" case answered from the samples.

### Phase 1 — Onboarding interview → goals files
- **Goal:** capture *real, opinionated* goals + your prioritisation judgement.
- **Build:** `onboard` skill — an interview (not a form) that drafts
  `goals/{company,team,personal}.md` and `weightings.md`, then you edit.
- **Files/skills:** `onboard/SKILL.md`, `templates/goal.*`, `weightings.md`.
- **DoD:** four goal files exist and you've edited them; `weightings.md`
  encodes concrete trade-offs (e.g. "P0 customer escalation > committed roadmap
  > internal tooling > opportunistic"); each file header marks it human-owned.

### Phase 2 — Daily digest / prioritisation
- **Goal:** a ranked brief you'd actually act on, grounded in goals + state.
- **Build:** `daily-brief` skill (reads `index.md` + context + today's
  `daily/` log + QMD fallback → `briefs/YYYY-MM-DD.md`) and `query` skill.
- **Files/skills:** `daily-brief/SKILL.md`, `query/SKILL.md`, `templates/brief.md`.
- **DoD:** brief ranks priorities with reasoning, **each priority cites its
  grounding (goal + source)**, and your edits to the ranking are minor.
  → **This is the big go/no-go (Decision Point 2).**

### Phase 3 — Source ingestion → synthesized context
- **Goal:** real data flowing in, summarized with provenance, raw kept.
- **Build:** adapters `ingest_linear`, `ingest_granola`, `ingest_slack`
  (→ `~/sources/`); `ingest` skill synthesizes → `context/` pages +
  `context/slack.md` (rolling), updates `index.md` + `log.md`, cites raw.
  Suggest order **3a Linear → 3b Granola → 3c Slack** (easiest/cleanest first;
  Slack last as it's the constrained, noisiest one).
- **Files/skills:** `scripts/ingest_*`, `ingest/SKILL.md`, `templates/context.page.md`.
- **DoD:** an ingest of real data produces a context page whose every claim
  cites raw; `index.md`/`log.md` update; the Phase-2 brief measurably improves.

### Phase 4 — Drift detection → recalibration flags
- **Goal:** surface possible goal drift; never rewrite goals.
- **Build:** `drift-detect` skill, run on high-signal sources only; appends
  structured entries to `signals/recalibration.md`; a review ritual.
- **Files/skills:** `drift-detect/SKILL.md`, `templates/recalibration.entry.md`.
- **DoD:** a planted "drift" in a sample All Hands yields one specific flag
  (cites source + goal line + proposed delta + confidence); **zero writes to
  `goals/`**; no flags fire on benign sources.

### Phase 5 — Daily-log automation fallback
- **Goal:** de-risk the most fragile, highest-value input.
- **Build:** `draft-daily-log` skill → drafts `daily/YYYY-MM-DD.md` from
  calendar + Linear + Granola; you only edit. Requires the calendar adapter.
- **Files/skills:** `draft-daily-log/SKILL.md`, `ingest_calendar.*`, `templates/daily.log.md`.
- **DoD:** a generated draft needs only light editing and is clearly marked
  draft-vs-confirmed.

### Phase 6 — Lint pass (Karpathy's 3rd op)
- **Goal:** keep the brain coherent; catch stale/contradictory synthesis.
- **Build:** `lint` skill — contradictions, stale claims (citation older than
  its source / source changed), orphan pages, missing cross-refs, goal-vs-
  reality gaps. Subgraph scoping for cost; **sub-agent fan-out per subgraph**
  when it outgrows a single pass.
- **Files/skills:** `lint/SKILL.md`.
- **DoD:** lint catches a planted contradiction and a planted stale claim,
  emits an actionable report, and never auto-edits `goals/`.

*(Packaging: skills live loose under `plugin/chief-of-staff/skills/` from the
start but you run them directly; formal plugin packaging/marketplace manifest is
a finishing step after Phase 2 proves value — no reason to package nothing.)*

---

## 5. Decision points (stop and evaluate)

1. **After Phase 0 — Is QMD good enough?**
   Fork: (a) proceed with QMD as-is; (b) swap retrieval (different embedder, or
   ripgrep-first over the curated `index.md`); (c) lean harder on synthesized
   index and use QMD only as long-tail fallback. Cheap to decide, expensive to
   get wrong — everything sits on this.

2. **After Phase 2 — Is the prioritisation loop actually useful?** *(the main
   go/no-go)*
   Fork: (a) invest in ingestion automation (Phase 3+); (b) the data's fine but
   the *judgement* is off → iterate `weightings.md` and the brief skill before
   automating; (c) it's not useful → stop. Your "don't automate until the loop
   is proven" principle lives or dies here.

3. **After Phase 4 — Is LLM-maintained synthesis trustworthy across cycles?**
   Fork: (a) keep compounding synthesis; (b) trust is leaking (stale-as-fact) →
   reduce synthesis, retrieve more at query time (toward RAG), tighten
   provenance; (c) middle path → raise lint cadence / pull Phase 6 forward.
   This is the explicit checkpoint on Karpathy's documented failure mode.

---

## 6. Open questions (need your answers before we lock the plan)

**Sources / access**
1. **Slack plan tier?** Free/Pro/Business+/Enterprise — this decides whether
   private channels + DMs are reachable at all, and whether we use an admin
   export or a user-token tool (`slackdump`, `xoxp`). Which exact channels, and
   how far back?
2. **Granola:** OK to read the local cache via a community tool (no official
   API)? Any meetings too sensitive to store in `~/sources/`?
3. **Linear:** API token available, and scope to which team(s)?
4. **Calendar (for Phase 5):** macOS Calendar, Google Calendar, or skip the
   calendar input?

**Architecture / privacy**
5. **Raw location:** OK with the sibling `~/sources/` (my recommendation) vs
   `~/brain/raw/`?
6. **Fully local / no cloud embeddings?** QMD defaults to local EmbeddingGemma.
   Confirm everything (incl. embeddings) stays on-device while testing.

**Runtime / cadence**
7. **How should the daily brief fire?** Manual in Claude Code to start, or a
   Cowork scheduled task? (Note from research: Cowork schedules only run while
   the Mac is awake *and* Claude Desktop is open — fine for a morning brief,
   not for unattended overnight jobs.)
8. **Delivery:** brief written to `briefs/` only, or also pushed somewhere
   (Slack DM to self / email)?

**Scope**
9. **Initial backlog depth & retention:** how much history to ingest on day one,
   and how long to keep raw?
10. **Packaging:** keep skills loose during dev and package the plugin after
    Phase 2 (my suggestion), or package earlier?

---

*Next step: answer §6 (especially 1, 4, 5, 7) and I'll lock this into a v2 and
begin Phase 0. No code until you approve.*
