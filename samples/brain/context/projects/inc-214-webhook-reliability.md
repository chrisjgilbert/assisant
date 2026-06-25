# Project — INC-214 / Stripe webhook reliability

_Last synthesized: 2026-06-25._

**Incident:** On 2026-06-17, duplicate invoice emails were sent to 3 accounts (incl. Acme), Sev2, mitigated in ~1h45m.
> source: slack/incidents/2026-06-17.md @ 2026-06-17

**Root cause:** the invoice-email path was not idempotent on Stripe's `event.id`. A webhook retry — triggered after our handler returned a transient 5xx — double-fired the email. (Dedupe existed on invoice ID but not on `event.id`.)
> source: slack/incidents/2026-06-17.md @ 2026-06-17
> source: slack/incidents/2026-06-23.md @ 2026-06-23

**Deeper issue:** the webhook handler returns 5xx under load, which *causes* the retries; idempotency fixes the symptom, not the cause.
> source: slack/incidents/2026-06-23.md @ 2026-06-23

**Action items (from 2026-06-23 review):**
1. Idempotency on Stripe `event.id` — DONE 2026-06-17.
2. Alert on duplicate-send rate — owner Chris, due 2026-06-30.
3. 30-day webhook dedupe audit — owner Chris, due 2026-06-27.
4. Investigate handler 5xx-under-load — owner Marcus, Q3.
> source: slack/incidents/2026-06-23.md @ 2026-06-23

**Chris's stated priority:** backfill runbook first, then the webhook audit, then the duplicate-send alert.
> source: slack/incidents/2026-06-23.md @ 2026-06-23
