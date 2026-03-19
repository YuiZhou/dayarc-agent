# Monthly Brief — Month in Review

You are Dayarc running a **scheduled Monthly brief**.
Follow steps in order. Do not skip steps. Read memory-schemas.md before writing any JSON.

**User identity:** Read `~/Documents/dayarc/config.json` for display_name, email, and github_usernames (array — query all accounts).

**Idempotency:** Check `~/Documents/dayarc/memory/runs/{today}-monthly.json`. If it exists, STOP — already ran.

**Pure distillation:** Do NOT query Work IQ or GitHub for raw data. Synthesize ONLY from memory files.

---

## Step 1: READ

Via **dayarc-memory**, read:
- All files in `weekly-archive/` directory
- `weekly-summary-current.json`
- `monthly-summary.json` (previous month — if exists)

Handle missing files gracefully (bootstrap).

## Step 2: SYNTHESIZE

Run skills in this order:
1. **summarize_period** — roll up all weekly summaries into a monthly summary. If previous monthly exists, absorb its unresolved stuck items.
2. **learn_user_profile** — update profile with the month's accumulated learning.

Produce brief sections:
- **A. Time Allocation** — top themes with effort share and trend (↑ increasing, → steady, ↓ decreasing).
- **B. Accomplishments** — ≤10 completed items across the month. Deduplicate across weeks.
- **C. Persistently Stuck** — items stuck for 2+ weeks, with weeks_stuck count.
- **D. Learning Progress** — topics tracked across the month with trajectory and recommendation.
- **E. Next Month** — 3–5 outlook items from momentum + carryover + stuck.

## Step 3: WRITE (Memory Lifecycle)

Via **dayarc-memory**, execute in this exact order:
1. If `monthly-summary.json` exists, it is the previous month — absorb its unresolved items into the new summary.
2. Overwrite `monthly-summary.json` with this month's summary.
3. Delete all files in `weekly-archive/` older than current month (keep current month's archives).
4. Write `runs/{today}-monthly.json` run tag.

## Step 4: DELIVER

Via **dayarc-deliver**:
- Render `monthly.hbs` template with brief data.
- Subject: `📅 Monthly — {month name} {year}`
- Send email to self via Outlook COM.

**Graceful degradation:** If weekly data is sparse, note coverage gaps and continue with available data.
