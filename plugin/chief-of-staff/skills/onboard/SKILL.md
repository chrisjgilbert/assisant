---
name: onboard
description: Conducts an opinionated, adaptive onboarding INTERVIEW (not a form) to draft the human-owned goal files and prioritisation weightings. Use on first-time setup, or whenever the user wants to (re)establish goals and trade-off rules.
---

# onboard — interview the user into goals + prioritisation judgement

## Purpose
Sit down with the user and *interview* them — ask, listen, follow up — until you
understand their company goals, product-team goals, personal/career aims, and
crucially their **prioritisation judgement** (the concrete trade-off rules that
decide what beats what when time is scarce). Then draft
`~/chief-of-staff/brain/goals/{company,team,personal}.md` and `~/chief-of-staff/brain/goals/weightings.md`
from the repo templates, present them, and iterate WITH the user, who edits.

This is the ONLY skill permitted to write under `~/chief-of-staff/brain/goals/`, and only
collaboratively, as drafts the user reviews.

## Hard guardrails (read first)
- **This is an interview, NOT a questionnaire.** Ask one focused question (maybe
  two) at a time, listen, then ask a follow-up shaped by the answer. Never dump a
  numbered list of questions and wait for a wall of text.
- **Goals are HUMAN-OWNED.** You only *draft* the files from the interview and
  present them. The user edits and confirms. Mark every file HUMAN-OWNED in its
  header and state explicitly that ingestion never writes here.
- **Writes are confined to:** `~/chief-of-staff/brain/goals/company.md`,
  `~/chief-of-staff/brain/goals/team.md`, `~/chief-of-staff/brain/goals/personal.md`,
  `~/chief-of-staff/brain/goals/weightings.md`, and a log line in `~/chief-of-staff/brain/log.md`. Nothing
  else. Never touch `context/`, `index.md`, `sources/`, or `signals/`.
- **No confabulation.** Only write what the user told you. If a section is thin,
  leave a clearly-marked TODO for the user rather than inventing goals.
- **weightings.md must be CONCRETE** — ordered, named trade-off rules, not
  platitudes. "Focus on what matters" is a failure; "a customer escalation with
  revenue risk beats committed roadmap work; committed roadmap beats internal
  tooling; internal tooling beats opportunistic work — unless the opportunistic
  work unblocks a teammate today" is the target.

## Inputs it reads
- Repo templates (the scaffold for each draft):
  - `templates/goal.company.md`
  - `templates/goal.team.md`
  - `templates/goal.personal.md`
  - `templates/weightings.md`
- Any existing `~/chief-of-staff/brain/goals/*` files — if re-running, read them first and treat
  the interview as a *revision* of what's there, not a blank start.

## Procedure
1. **Frame it.** Tell the user this is a short interview to capture their goals
   and how they prioritise, and that everything you draft is theirs to edit —
   nothing is auto-applied.
2. **If re-onboarding,** read existing `~/chief-of-staff/brain/goals/*` and summarize them back:
   "Here's what I have today — what's changed?" Interview around the deltas.
3. **Interview — company goals.** What is the company trying to achieve this
   year/quarter? What does success look like? What would failure look like?
   Follow the threads that have energy or stakes.
4. **Interview — product-team goals.** What is the team on the hook for? Which
   commitments are firm vs aspirational? Who depends on them? What's the current
   biggest risk to the team's commitments?
5. **Interview — personal goals / career aims.** What does the user want to grow
   into? What kind of work do they want more / less of? Any explicit career
   milestones this year?
6. **Interview — PRIORITISATION JUDGEMENT (the crux; spend the most time here).**
   Surface their real trade-off rules with concrete, adversarial scenarios:
   - "It's Tuesday, you have a customer escalation, a committed roadmap deadline
     Friday, and a teammate blocked on your review — what gives, and why?"
   - "When does opportunistic / interesting work win over committed work? When
     does it never?"
   - "What's the thing you protect even in a bad week?"
   - "What kinds of requests do you reflexively say no to?"
   Push until you can write down an *ordered* ranking of work-types plus the
   override conditions that flip it. These become `weightings.md`.
7. **Draft from templates.** Fill `goal.company.md` → company.md,
   `goal.team.md` → team.md, `goal.personal.md` → personal.md, and
   `weightings.md` → weightings.md, using ONLY what the user said. Add a
   HUMAN-OWNED header to each (see format). Leave explicit `TODO:` markers where
   the interview didn't cover something.
8. **Present + iterate.** Show the user each draft (or write them and point the
   user at the paths). Invite edits. Revise on request. Do NOT consider this done
   until the user signs off; remind them they can freely edit the files directly.
9. **Log.** Append one line to `~/chief-of-staff/brain/log.md` (see format).

## Outputs it writes

### HUMAN-OWNED header (top of every goals file)
```markdown
---
title: Company goals
category: goals
owner: human                # HUMAN-OWNED — edit freely
last-reviewed: 2026-06-25
---
> HUMAN-OWNED. Drafted via the `onboard` interview; the user edits this.
> Ingestion NEVER writes here — drift is only ever *proposed* in
> ~/chief-of-staff/brain/signals/recalibration.md for your review.
```

### weightings.md — concrete, ordered trade-off rules (not platitudes)
```markdown
---
title: Prioritisation weightings
category: goals
owner: human                # HUMAN-OWNED
last-reviewed: 2026-06-25
---
> HUMAN-OWNED. The daily-brief skill RANKS against these rules.

## Default order of work-types (highest first)
1. Customer escalation with revenue / trust risk
2. Committed roadmap work with a dated external commitment
3. Unblocking a teammate (review, decision, handoff) due today
4. Internal tooling / tech-debt with a clear payoff
5. Opportunistic / exploratory work

## Override rules (when the default flips)
- Unblocking a teammate jumps ABOVE committed roadmap when they're idle today.
- A roadmap item slips below internal tooling if the tooling is the thing
  blocking the roadmap item.
- Opportunistic work only wins when it's <30 min AND compounds (reusable).

## Things I protect even in a bad week
- Deep-work block for <named priority>.
- 1:1s with directs.

## Reflexive no's
- New meetings without an agenda; status work that a doc could carry.
```

### Log line — append to `~/chief-of-staff/brain/log.md`
```markdown
## [2026-06-25] onboard | drafted goals/{company,team,personal}.md + weightings.md (user to edit)
```

## Example
First-time setup. You frame the interview, then converse: company → team →
personal → prioritisation, asking follow-ups, not reciting a list. On the
trade-off question the user reveals "escalations always win, but I never let an
escalation eat my one deep-work block unless a customer is actively down." You
capture that as an ordered list plus a named override in `weightings.md`, draft
the four files from the templates with HUMAN-OWNED headers and a couple of
`TODO:` markers where personal goals were vague, present them, take two edits
from the user, and append the onboard log line.
