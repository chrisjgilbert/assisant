# Setup — running V1 on a Mac

This guide gets the **V1 vertical slice** (Slack + Google Calendar → synthesis →
retrieval → daily brief) running on macOS. For the why behind each piece, see
[ARCHITECTURE.md](ARCHITECTURE.md); for the decisions, see [BUILD_PLAN.md](BUILD_PLAN.md).

> Commands marked **(verify on first run)** depend on your machine, your QMD
> version, or the exact Cowork/MCP tool names. Treat them as placeholders and
> confirm the real invocation the first time through.

Throughout, `REPO` means the path to this repo (e.g. `~/code/assisant`). The brain
and raw layers live **outside** the repo, in your home directory.

---

## (a) Prerequisites

- **Claude Desktop + Cowork on a paid plan.** Cowork connectors require it.
- **Slack connector** connected in Cowork, with read access to the channels/DMs you
  care about. Keep it **read-only** for this system — never grant or use
  `send_message`.
- **Google Calendar connector** connected in Cowork (read access to your calendars).
- **Node and/or Bun** installed (for QMD). On a Mac:
  ```sh
  brew install node      # and/or:  brew install oven-sh/bun/bun
  ```
- Confirm both connectors actually return data *before* building anything — this is
  Phase 0 in the build plan. (verify on first run)

---

## (b) Install and configure QMD

QMD is the local markdown search engine + MCP daemon used for retrieval. A setup
script is provided.

```sh
cd "$REPO"
./scripts/qmd_setup.sh          # (verify on first run)
```

This should: install QMD, create **two collections** — `brain` (PRIMARY, your
synthesis) and `sources` (SECONDARY, immutable raw) — build the local embeddings,
and register the QMD MCP daemon with Claude Code. After it finishes, confirm the MCP
tools are visible to Claude and note their exact names. (verify on first run)

> QMD indexes the brain as the primary collection and raw sources as secondary.
> Retrieval reads `~/brain/index.md` first; QMD search is the fallback.

---

## (c) Bootstrap the brain

Create the brain and raw directories and seed them from this repo's templates and
config.

```sh
cd "$REPO"
./scripts/bootstrap_brain.sh    # (verify on first run)
```

This should create `~/brain/` (with `goals/ context/ daily/ briefs/ config/
signals/`, plus `index.md`, `log.md`, `CLAUDE.md`) and `~/sources/` (with `slack/`
and `calendar/`), and copy the markdown templates from `templates/` and the config
template into place. Both directories are created **outside** this repo and are
never committed.

---

## (d) Populate `~/brain/config/sources.yml`

Copy the shipped template into the brain and edit it to list your real sources:

```sh
cp "$REPO/config/sources.example.yml" ~/brain/config/sources.yml
$EDITOR ~/brain/config/sources.yml
```

Set a few Slack channels under `slack.channels.include`. **DMs and @-mentions are on
by default.** A minimal example:

```yaml
slack:
  window_days: 14
  channels:
    include:
      - "#eng-product"
      - "#incidents"
    ignore: ["#random"]
  dms: { include: true }      # all DMs
  mentions: true              # @-mentions of you anywhere
  discovery: { enabled: true, queue: "signals/new-channels.md" }
calendar:
  window_days: 14
  calendars: ["primary"]
```

The populated `sources.yml` is **personal data** and lives only in `~/brain/`; the
repo ships only `config/sources.example.yml`. New channel memberships are proposed
into `~/brain/signals/new-channels.md`, never auto-added.

---

## (e) Install the skills

The skills live in the plugin at `plugin/chief-of-staff/`. Two ways to make them
available to Claude Code:

**Option 1 — enable as a local plugin (simplest, recommended).** Point Claude Code
at the local plugin directory so it loads the whole `chief-of-staff` plugin and all
its skills together.

```sh
# Register/enable the local plugin (verify the exact command for your version):
claude plugin install "$REPO/plugin/chief-of-staff"   # (verify on first run)
```

**Option 2 — symlink individual skills into your skills directory.** Useful if you
only want some skills, but you have to maintain each link.

```sh
mkdir -p ~/.claude/skills
for s in pull ingest onboard daily-brief query; do
  ln -s "$REPO/plugin/chief-of-staff/skills/$s" ~/.claude/skills/"$s"
done
```

**Use Option 1** unless you have a reason not to — it keeps the skills versioned and
updated together with the repo.

After installing, confirm the skills appear in Claude Code. (verify on first run)

---

## (f) The daily loop

Run the onboarding interview **once**, up front, then run the daily loop each day.

**One-time: onboarding interview.** This drafts your human-owned goals.

```
Run the onboard skill.
```

It interviews you and drafts `~/brain/goals/{company,team,personal}.md` plus
`weightings.md`. **Edit these yourself** — they are human-owned and the brief ranks
against them. Ingestion never writes them.

**Each day:**

1. **pull** — fetch the configured window via the Cowork connectors and write
   immutable raw to `~/sources/`. Slack stays read-only; new channel memberships
   are appended to `~/brain/signals/new-channels.md` for your review.
   ```
   Run the pull skill.
   ```
2. **ingest** — synthesize the new raw into `~/brain/context/*`, update `index.md`
   and `log.md`, with every claim cited as `> source: <path> @ <date>`. May append
   proposals to `signals/recalibration.md`; never touches `goals/`.
   ```
   Run the ingest skill.
   ```
3. **daily-brief** — produce the ranked brief over goals + `context/slack.md` +
   today's calendar (QMD fallback) into `~/brain/briefs/YYYY-MM-DD.md`, a file
   Cowork can present.
   ```
   Run the daily-brief skill.
   ```

**Ad-hoc: query.** Ask questions over the brain at any time.

```
Run the query skill: "what did I decide about <X> last week?"
```

V1 cadence is **manual** — you run these in Claude Code yourself.

---

## (g) Verify QMD retrieval

The repo ships a `benchmark/` directory with sample source files and benchmark Q/A
to check that retrieval actually returns the right source.

```sh
cd "$REPO"
ls benchmark/                  # sample sources + Q/A
# Run the benchmark per its README/runner: (verify on first run)
```

Target: QMD returns the correct source for **≥80%** of the benchmark questions. If
it falls short, swap the embedder or lean harder on the curated `index.md` (see
Decision Point 1 in [BUILD_PLAN.md](BUILD_PLAN.md)).

---

## Where things live (recap)

| Layer | Location | Committed? |
|---|---|---|
| Raw sources (immutable) | `~/sources/` | No (outside repo) |
| The brain (synthesis + goals) | `~/brain/` | No (outside repo) |
| Behaviour (skills/scripts/templates) | this repo | Yes |
| Populated config | `~/brain/config/sources.yml` | No |
| Config template | `config/sources.example.yml` | Yes |
