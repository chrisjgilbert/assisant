# Context — Slack (rolling synthesis)

_Last synthesized: 2026-06-25. Covers #eng-payments, #team-billing-squad, #incidents, and DMs with Priya Raman and Marcus Webb, ~2026-06-15 to 2026-06-24._

## Usage-Based Billing (UBB) metering

The team decided to ship `ubb_metering_v2` behind a feature flag, default off, enabled per-account starting with the Acme pilot — new-usage metering only, with backfill held out of the flagged path until a runbook and dry-run exist.
> source: slack/eng-payments/2026-06-15.md @ 2026-06-15

New-usage metering and backfill were deliberately split into separate workstreams; Chris owns the new-usage path and the flag, Marcus owns backfill design. Target was the flag live in staging by 2026-06-22.
> source: slack/eng-payments/2026-06-15.md @ 2026-06-15

The flag landed in staging on the night of 2026-06-22 (one day late), with Acme toggled on in staging only and metering events flowing — clearing the staging milestone.
> source: slack/eng-payments/2026-06-23.md @ 2026-06-23

The flag default was forced to off in the DB migration (not just code config) after a prior `invoice_pdf_v2` mistake.
> source: slack/eng-payments/2026-06-18.md @ 2026-06-18

Acme accepted new-usage-only metering for the pilot, allowing backfill to land afterward.
> source: slack/team-billing-squad/2026-06-16.md @ 2026-06-16

## The UBB backfill runbook (repeatedly deferred)

The backfill runbook has been the persistently deferred item. Chris committed to drafting it the week of 2026-06-15, but flag work consumed the week; by 2026-06-18 it was still unstarted and being "carried forward."
> source: slack/eng-payments/2026-06-15.md @ 2026-06-15
> source: slack/eng-payments/2026-06-18.md @ 2026-06-18

It remains Chris's #1 item and is the gating dependency for enabling Acme in production; Priya needs it done by Friday 2026-06-26.
> source: slack/eng-payments/2026-06-23.md @ 2026-06-23
> source: slack/dm-priya-raman/2026-06-19.md @ 2026-06-19

Marcus's backfill happy-path design is done and awaiting Chris's review before the Thursday roadmap sync; the runbook must require a dry-run on a copy of prod data before any real backfill.
> source: slack/dm-marcus-webb/2026-06-24.md @ 2026-06-24

## INC-214 — duplicate invoice emails

On 2026-06-17, duplicate invoice emails went out to 3 accounts including Acme (Sev2). Root cause: the invoice-email path was not idempotent on Stripe's `event.id`; a webhook retry after a transient 5xx double-fired the email. Mitigated in ~1h45m via an idempotency check on `event.id` and pausing then re-enabling the email worker.
> source: slack/incidents/2026-06-17.md @ 2026-06-17
> source: slack/incidents/2026-06-23.md @ 2026-06-23

Review action items: (1) idempotency on `event.id` — done; (2) alert on duplicate-send rate — owner Chris, due 2026-06-30; (3) 30-day webhook dedupe audit — owner Chris, due 2026-06-27; (4) investigate handler 5xx-under-load — owner Marcus, Q3.
> source: slack/incidents/2026-06-23.md @ 2026-06-23

## Invoice PDF redesign (parked)

Invoice PDF v2 mocks are final in Figma ("Invoice v2 — final"), but eng work is parked until UBB is in staging and realistically slipped to Q3. Priya explicitly asked Chris not to pick it up even if Leo asks.
> source: slack/eng-payments/2026-06-18.md @ 2026-06-18
> source: slack/team-billing-squad/2026-06-22.md @ 2026-06-22
> source: slack/dm-priya-raman/2026-06-19.md @ 2026-06-19

## Direct asks of Chris

Priya needs: the backfill runbook by 2026-06-26, and a couple of skip-level bullets on UBB work by Monday morning; she also wants Chris to bring stretch/growth-toward-staff areas to the Tuesday 1:1.
> source: slack/dm-priya-raman/2026-06-19.md @ 2026-06-19

Marcus needs: a review of his backfill design doc before the Thursday roadmap sync, and confirmation that a dry-run on a copy of prod data is feasible.
> source: slack/dm-marcus-webb/2026-06-24.md @ 2026-06-24
