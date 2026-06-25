# Prioritisation Weightings

<!--
  HUMAN-OWNED. Ingestion never writes here; proposed changes go to
  signals/recalibration.md for you to review and apply by hand.

  Copied into ~/chief-of-staff/brain/goals/weightings.md by the bootstrap script, then edited.
  This file encodes YOUR prioritisation JUDGEMENT as concrete, ordered rules so
  the daily brief can rank competing demands the way you actually would. The
  goal.*.md files say what matters; THIS file says what beats what when two
  things both matter and you can't do both today.

  Everything below is a WORKED EXAMPLE. Edit it to match how you really decide —
  reorder, rename, delete, add. The brief only ranks as well as this is honest.
-->

> ownership: HUMAN-OWNED — ingestion proposes via signals/recalibration.md, never edits this file.
> last reviewed: <FILL IN YYYY-MM-DD>

## Default priority order (highest first)
<!-- When two items compete and nothing below overrides, higher wins. -->
1. **Customer escalation** — a paying customer is blocked or churning.
2. **Committed roadmap commitment** — work we've externally/contractually promised this cycle.
3. **Team-unblocking** — something only I can clear that is blocking a teammate.
4. **Internal tooling / tech-debt** — improves our own velocity but no external clock.
5. **Opportunistic exploration** — interesting, speculative, no one is waiting.

## Tie-breakers
<!-- When two items sit at the same level above, apply these in order. -->
1. Sooner hard deadline wins.
2. Larger number of people unblocked wins.
3. Serves a higher-level goal (company > team > personal) wins.
4. Smaller effort to "done" wins (clear the quick one, then return).

## What I deprioritise
<!-- Things that feel urgent but usually aren't; push these down by default. -->
- Meetings I'm an optional attendee on with no decision to make.
- Polishing internal tooling that already works "well enough".
- Inbound that has a clear owner who isn't me.
- Net-new exploration during a committed-delivery crunch.

## Red-flag overrides (these jump to the TOP regardless of order above)
<!-- Conditions that suspend the normal order until resolved. -->
- **P0 / SEV1 incident** — drop everything; production is down or data at risk.
- **Security or data-exposure issue** — treat as P0.
- **Direct ask from <FILL IN: e.g. my manager / on-call escalation> flagged urgent.**
- **A commitment due today at risk of slipping** — escalate before it slips, not after.

## Notes
<!-- Personal nuance the rules above can't capture; the brief should respect this. -->
<FILL IN e.g. "Protect deep-work mornings", "Fridays = no new commitments">
