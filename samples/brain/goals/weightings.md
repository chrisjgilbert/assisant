# Goals — Weightings (prioritisation trade-offs)

<!-- HUMAN-OWNED. Ingestion proposes; it never writes this file. -->

How to rank competing items when building the daily brief. Higher = more important.

| Weight | Class of work | Rationale |
|-------:|---------------|-----------|
| **10** | Gating items that unblock the Acme UBB pilot (esp. the backfill runbook) | Single must-hit; everything else flexes around it. |
| **9** | Customer-visible billing correctness (INC-214 follow-ups: dedupe audit, duplicate-send alert) | Billing errors are existential; zero tolerance. |
| **7** | Direct asks from my manager (Priya) with a deadline | Trust + visibility; e.g. skip-level bullets, runbook. |
| **6** | Direct asks from my tech lead (Marcus) blocking a milestone | Review of backfill design before the roadmap sync. |
| **5** | UBB new-usage metering polish / staging hardening | Important but the must-hit (flag in staging) is already met. |
| **2** | Invoice PDF redesign | Explicitly parked to Q3; do NOT start early. |

Tie-breakers:
- Prefer the item I have been **avoiding/deferring** over a fresh, fun item of equal weight (anti-procrastination bias).
- Prefer items with a **hard external deadline** this week over open-ended ones.
- A blocked-on-me item that blocks a teammate outranks a same-weight solo item.
