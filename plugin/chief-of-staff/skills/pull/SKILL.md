---
name: pull
description: Connector-driven fetch of Slack and Google Calendar into the immutable raw layer (~/chief-of-staff/sources/). Use to refresh raw sources before an ingest (e.g. at the start of the daily loop) or on demand when newer source data is needed. Read-only on Slack; never sends or posts anything.
---

# pull — fetch connectors into the immutable raw layer

## Purpose
Snapshot the configured Cowork connectors (Slack + Google Calendar in V1) into
the **immutable raw layer** at `~/chief-of-staff/sources/`. This is the "fetcher into raw," NOT
live-RAG: connectors are mutable systems of record, so you pin what each later
synthesis was derived from by writing a dated, immutable snapshot first.
Synthesis happens later in the `ingest` skill — `pull` does no synthesis.

## Hard guardrails (read first)
- **Slack is READ-ONLY.** Only call Slack read/fetch tools (list channels, read
  messages, read DMs, read mentions). NEVER call any write/send tool
  (e.g. send_message, post, create_channel, react). If the only available Slack
  tool would mutate Slack, stop and report instead.
- **Writes are confined to:** `~/chief-of-staff/sources/**`, `~/chief-of-staff/brain/signals/new-channels.md`,
  and `~/chief-of-staff/brain/log.md`. Nothing else.
- **NEVER write** `~/chief-of-staff/brain/goals/`, `~/chief-of-staff/brain/context/`, or `~/chief-of-staff/brain/index.md`.
- **Raw is immutable.** Do not overwrite an existing snapshot. If a re-pull of an
  already-captured window differs, write a NEW dated snapshot and note the
  supersession in its frontmatter rather than editing the old file.
- **Channel discovery proposes, never subscribes.** Append new memberships to
  `signals/new-channels.md`; never add to `include` in config yourself.

## Inputs it reads
- `~/chief-of-staff/brain/config/sources.yml` — the source/channel selection. Schema:
  ```yaml
  slack:
    window_days: 14                 # default lookback window
    channels:
      include:                      # names, or per-channel override objects
        - "#eng-product"
        - { name: "#incidents", priority: high, window_days: 30 }
      ignore: ["#random", "#watercooler"]
    dms:    { include: true }       # true = all DMs; or { include: true, people: ["Alice","Bob"] }
    mentions: true                  # fetch @-mentions of you anywhere, incl. unwatched channels
    discovery: { enabled: true, queue: "signals/new-channels.md" }
  calendar:
    window_days: 14
    calendars: ["primary"]
  ```
- `~/chief-of-staff/brain/log.md` — to determine which days/windows are already captured
  (idempotency).
- Existing files under `~/chief-of-staff/sources/` — to avoid duplicating captured days.

## Procedure
1. **Load config.** Read `~/chief-of-staff/brain/config/sources.yml`. Resolve effective windows:
   per-channel `window_days` overrides `slack.window_days`; calendar uses
   `calendar.window_days`. Today is the range end (use the current date).
2. **Compute idempotency.** From `~/chief-of-staff/brain/log.md` and existing `~/chief-of-staff/sources/` files,
   determine which (channel, day) and (calendar, day) snapshots already exist.
   Only fetch missing or changed windows.
3. **Resolve Slack channels to STABLE IDs.** Names change, IDs don't. For each
   `include` entry, resolve the human name to its channel id via a Slack read
   tool. Record BOTH id and name. Drop anything in `ignore`.
4. **Fetch Slack (read-only).** For each included channel, plus DMs (if
   `dms.include`, optionally scoped to `dms.people`), plus your @-mentions (if
   `mentions`), fetch messages within that target's window using ONLY read tools.
5. **Write Slack raw snapshots.** Per channel/DM, write
   `~/chief-of-staff/sources/slack/<channel-or-dm-slug>/YYYY-MM-DD.md` (and/or `.json` for the
   structured payload) with the frontmatter below. The slug is derived from the
   channel/DM name; the stable id is recorded in frontmatter.
6. **Fetch + write Calendar.** For the calendars in `calendar.calendars`, fetch
   events within `calendar.window_days` and write
   `~/chief-of-staff/sources/calendar/YYYY-MM-DD.md` with frontmatter.
7. **Channel discovery.** List the channels you are a **member** of. Diff against
   `include ∪ ignore`. For each new membership, append one entry to
   `~/chief-of-staff/brain/signals/new-channels.md` (see format). NEVER auto-add to `include`.
8. **Log.** Append one line to `~/chief-of-staff/brain/log.md` (see format).
9. **Report.** Summarize: channels fetched, message count, calendar days, new
   channels queued, anything skipped (already captured) or refused (write tools).

## Outputs it writes

### Slack raw — `~/chief-of-staff/sources/slack/<slug>/YYYY-MM-DD.md` (+ optional `.json`)
```yaml
---
source: slack
channel: "#eng-product"        # human name at fetch time
channel_id: C0123ABCD          # STABLE id (authoritative)
fetched_at: 2026-06-25T09:14:00Z
range_start: 2026-06-11
range_end: 2026-06-25
# supersedes: 2026-06-24       # only if this re-pull differs from an earlier snapshot
---
```
Body = rendered messages (author, timestamp, text, thread structure). For DMs the
`channel` is a dm slug and `channel_id` the conversation id.

### Calendar raw — `~/chief-of-staff/sources/calendar/YYYY-MM-DD.md`
```yaml
---
source: calendar
calendars: ["primary"]
fetched_at: 2026-06-25T09:14:00Z
range_start: 2026-06-11
range_end: 2026-06-25
---
```
Body = events (title, start/end, attendees, location, description).

### Channel discovery — append to `~/chief-of-staff/brain/signals/new-channels.md`
One entry per newly-detected membership:
```markdown
- name: "#new-launch-room"
  id: C0987WXYZ
  topic: "Coordination for the Q3 launch"
  joined: 2026-06-22            # if available
  activity: high               # recent activity level
  suggested: include           # include | ignore (a proposal only)
```

### Log line — append to `~/chief-of-staff/brain/log.md`
```markdown
## [2026-06-25] pull | 6 channels, 412 messages, 2 calendar days, 1 new channel queued
```

## Example
Given `sources.yml` with `include: ["#eng-product", { name: "#incidents", window_days: 30 }]`,
`dms.include: true`, `mentions: true`, run on 2026-06-25:
- Resolve `#eng-product`→`C0123ABCD` (14d) and `#incidents`→`C0456EFGH` (30d).
- Read messages (read-only) for both, all DMs, and your mentions.
- Write `~/chief-of-staff/sources/slack/eng-product/2026-06-25.md`,
  `~/chief-of-staff/sources/slack/incidents/2026-06-25.md`, DM snapshots, and
  `~/chief-of-staff/sources/calendar/2026-06-25.md`.
- Detect membership in `#new-launch-room` (not in include/ignore) → append to
  `signals/new-channels.md`.
- Append: `## [2026-06-25] pull | 6 channels, 412 messages, 1 calendar day, 1 new channel queued`.
