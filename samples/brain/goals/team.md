# Goals — Team (Billing Squad)

<!-- HUMAN-OWNED. Ingestion proposes; it never writes this file. -->

The Billing Squad owns metering, invoicing, and the Stripe integration. This quarter:

1. **Ship the UBB metering pilot for Acme.** `ubb_metering_v2` behind a flag, new-usage metering live, backfill ready with a runbook + dry-run before any prod backfill. This is the one must-hit; everything else flexes.
2. **Close out INC-214 properly.** Idempotency is done; finish the duplicate-send alert and the 30-day webhook dedupe audit, and start the deeper handler-stability work.
3. **Park invoice PDF redesign until UBB is in staging.** Mocks are done; it's a Q3 item. Do not start eng work early.

Operating rules:
- Blameless incident reviews — capture action items, not fault.
- Keep the Slack connector read-only; never let automation post on our behalf.
