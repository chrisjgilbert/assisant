# Project — Usage-Based Billing (UBB) metering

_Last synthesized: 2026-06-25._

**Goal:** meter real usage for the Acme pilot by end of Q2 (customer commitment). Full GA not required for the pilot.
> source: slack/eng-payments/2026-06-15.md @ 2026-06-15

**Rollout decision:** ship `ubb_metering_v2` behind a feature flag, default off, enabled per-account starting with Acme. New-usage metering only; backfill stays out of the flagged path until a runbook + dry-run exist.
> source: slack/eng-payments/2026-06-15.md @ 2026-06-15

**Workstream split & ownership:**
- New-usage metering + flag — owner Chris.
- Backfill design — owner Marcus; happy-path design now done.
> source: slack/eng-payments/2026-06-15.md @ 2026-06-15
> source: slack/dm-marcus-webb/2026-06-24.md @ 2026-06-24

**Status:**
- Metering aggregation worker shipped (~2026-06-15).
- Flag wired (PR northwind/billing#1187), migration default forced off.
- Flag live in staging 2026-06-22 (one day late); Acme toggled on in staging only; metering events flowing.
> source: slack/team-billing-squad/2026-06-16.md @ 2026-06-16
> source: slack/eng-payments/2026-06-18.md @ 2026-06-18
> source: slack/eng-payments/2026-06-23.md @ 2026-06-23

**Gating item / risk:** the backfill runbook is unwritten and blocks enabling Acme in production. Due 2026-06-26. Must mandate a dry-run on a copy of prod data.
> source: slack/dm-priya-raman/2026-06-19.md @ 2026-06-19
> source: slack/dm-marcus-webb/2026-06-24.md @ 2026-06-24

**Next milestone:** prod-enable date for Acme to be locked at the Thursday roadmap sync, contingent on the runbook existing.
> source: slack/eng-payments/2026-06-23.md @ 2026-06-23
