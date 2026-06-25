# QMD Retrieval Benchmark — Questions

Phase 0 validation set. Each question has an **expected answer** (what a correct
response should say) and the **evidence file(s)** under `samples/` that must be
retrieved/cited for the answer to be grounded. Scoring is about whether QMD
returns the right *source* (see `README.md`), not about exact answer wording.

In-world "today" is **2026-06-25**. "Chris" = the user.

---

### Q1 — Decision recall (factual)
**Q:** What did we decide about the UBB metering rollout?
**Expected:** Ship `ubb_metering_v2` behind a feature flag, default off, enabled per-account starting with the Acme pilot; new-usage metering only, with backfill held out of the flagged path until a runbook + dry-run exist.
**Evidence:** `samples/sources/slack/eng-payments/2026-06-15.md`; synthesis: `samples/brain/context/projects/ubb-metering.md`, `samples/brain/context/slack.md`

### Q2 — Factual lookup
**Q:** What was the root cause of INC-214?
**Expected:** The invoice-email path wasn't idempotent on Stripe's `event.id`; a webhook retry after a transient 5xx double-fired the email, sending duplicate invoices to 3 accounts.
**Evidence:** `samples/sources/slack/incidents/2026-06-17.md`, `samples/sources/slack/incidents/2026-06-23.md`; synthesis: `samples/brain/context/projects/inc-214-webhook-reliability.md`

### Q3 — Behavioural ("what have I been avoiding")
**Q:** What have I been putting off / repeatedly deferring?
**Expected:** The UBB backfill runbook — committed to multiple times since 2026-06-15 but kept slipping because flag/other work took priority. It's the gating item for enabling Acme in prod, due 2026-06-26.
**Evidence:** `samples/sources/slack/eng-payments/2026-06-18.md`, `samples/sources/slack/eng-payments/2026-06-23.md`; synthesis: `samples/brain/context/slack.md`, `samples/brain/context/projects/ubb-metering.md`

### Q4 — People ("what does X need from me")
**Q:** What does Priya need from me?
**Expected:** The UBB backfill runbook by 2026-06-26, a couple of skip-level bullets on UBB work by Monday morning, and stretch/growth-toward-staff areas to bring to the Tuesday 1:1.
**Evidence:** `samples/sources/slack/dm-priya-raman/2026-06-19.md`; synthesis: `samples/brain/context/people/priya-raman.md`

### Q5 — People ("what does X need from me")
**Q:** What does Marcus need from me before the roadmap sync?
**Expected:** A careful review of his backfill happy-path design doc, and confirmation that a dry-run on a copy of prod data is feasible (to fold into the runbook as a mandatory step).
**Evidence:** `samples/sources/slack/dm-marcus-webb/2026-06-24.md`; synthesis: `samples/brain/context/people/marcus-webb.md`

### Q6 — Temporal ("what did I do last week")
**Q:** What did I ship or work on last week?
**Expected:** Shipped the metering aggregation worker, wired the `ubb_metering_v2` flag (PR #1187, migration default off), got the flag live in staging (2026-06-22), and led the INC-214 mitigation (idempotency fix on Stripe `event.id`).
**Evidence:** `samples/sources/slack/eng-payments/2026-06-18.md`, `samples/sources/slack/eng-payments/2026-06-23.md`, `samples/sources/slack/incidents/2026-06-17.md`; calendar: `samples/sources/calendar/2026-06-19.md`

### Q7 — Factual / status
**Q:** Is the `ubb_metering_v2` flag live in staging yet?
**Expected:** Yes — it went live in staging on the night of 2026-06-22 (one day late), with Acme toggled on in staging only and metering events flowing; this cleared the staging milestone.
**Evidence:** `samples/sources/slack/eng-payments/2026-06-23.md`; synthesis: `samples/brain/context/projects/ubb-metering.md`

### Q8 — Factual / ownership
**Q:** Who owns the UBB backfill design vs. the backfill runbook?
**Expected:** Marcus owns the backfill design (happy-path design done); Chris owns the operational backfill runbook (still unwritten).
**Evidence:** `samples/sources/slack/eng-payments/2026-06-15.md`, `samples/sources/slack/eng-payments/2026-06-23.md`, `samples/sources/slack/dm-marcus-webb/2026-06-24.md`; synthesis: `samples/brain/context/projects/ubb-metering.md`

### Q9 — Decision recall / status
**Q:** What's the status of the invoice PDF redesign?
**Expected:** Parked. Mocks are final in Figma, but eng work won't start until UBB is in staging and it has slipped to Q3; Priya explicitly asked Chris not to pick it up.
**Evidence:** `samples/sources/slack/eng-payments/2026-06-18.md`, `samples/sources/slack/team-billing-squad/2026-06-22.md`, `samples/sources/slack/dm-priya-raman/2026-06-19.md`; synthesis: `samples/brain/context/projects/invoice-pdf-redesign.md`

### Q10 — INC-214 action items (factual list)
**Q:** What are my open action items from the INC-214 review?
**Expected:** The 30-day webhook dedupe audit (due 2026-06-27) and the duplicate-send-rate alert (due 2026-06-30). (Idempotency on `event.id` is already done; the handler-5xx investigation is Marcus's, Q3.)
**Evidence:** `samples/sources/slack/incidents/2026-06-23.md`; synthesis: `samples/brain/context/projects/inc-214-webhook-reliability.md`

### Q11 — Combine 2+ sources (calendar + slack)
**Q:** What's on my calendar today-ish, and which of those meetings ties to the incident?
**Expected:** Around 2026-06-23 the calendar has the INC-214 incident review at 11:00 and a 1:1 with Priya; the INC-214 review corresponds to the incident writeup Chris owns. (Combines calendar + #incidents.)
**Evidence:** `samples/sources/calendar/2026-06-23.md`, `samples/sources/slack/incidents/2026-06-23.md`

### Q12 — Combine 2+ sources (priorities across goals + slack)
**Q:** Given my goals and what's open, what should my single top priority be this week?
**Expected:** The UBB backfill runbook (due 2026-06-26) — it's the weight-10 gating item that unblocks the Acme prod enable, it's the thing Chris keeps deferring, and both Priya and Marcus are waiting on it.
**Evidence:** `samples/brain/goals/weightings.md`, `samples/brain/goals/personal.md`, `samples/sources/slack/dm-priya-raman/2026-06-19.md`, `samples/sources/slack/dm-marcus-webb/2026-06-24.md`

### Q13 — Combine 2+ sources (deadline reconciliation)
**Q:** When does the backfill runbook need to be done, and why that date?
**Expected:** Friday 2026-06-26 — Priya set it as the gating item for the Acme prod enable (assumed early next week), and the prod-enable date is to be locked at the Thursday roadmap sync contingent on the runbook existing.
**Evidence:** `samples/sources/slack/dm-priya-raman/2026-06-19.md`, `samples/sources/slack/team-billing-squad/2026-06-16.md`, `samples/sources/slack/eng-payments/2026-06-23.md`

### Q14 — Negative control (not in the data)
**Q:** What did we decide about migrating off Stripe to Adyen?
**Expected:** Nothing — there is no discussion of Adyen or a payment-processor migration in the data. A correct system returns "not found / no evidence" rather than inventing an answer.
**Evidence:** NONE (negative control — no file should be confidently cited).

### Q15 — Negative control (plausible but absent)
**Q:** What's the status of the mobile app billing rewrite?
**Expected:** Nothing — there is no mobile app or mobile billing rewrite anywhere in the sources. A correct system returns "not found."
**Evidence:** NONE (negative control — no file should be confidently cited).
