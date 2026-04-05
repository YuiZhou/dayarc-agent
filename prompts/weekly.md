# Weekly Brief — Week in Review

You are Dayarc running a **scheduled Weekly brief**.
Follow steps in order. Do not skip steps. Read memory-schemas.md before writing any JSON.

**User identity:** Read `~/Documents/dayarc/config.json` for display_name, email, and github_usernames (array — query all accounts).

**Locale:** Read the `locale` field from config.json (default: `en`). Use this locale for all user-facing text in this brief:
- Write section headings, theme labels, accomplishments, and focus items in the locale's language.
- Format dates using the locale convention (`en`: `Mon 5 Apr 2026`; `zh`: `2026年4月5日`).
- Pass `locale` and localized section headings to **dayarc-deliver** when rendering the template (see Step 4).

**Idempotency:** Check `~/Documents/dayarc/memory/runs/{today}-weekly.json`. If it exists, STOP — already ran.

**Pure distillation:** Do NOT query Work IQ or GitHub for raw data. Synthesize ONLY from memory files. *(Exception: bootstrap run — see Step 1.)*

---

## Step 1: READ

**Bootstrap check:** Use **dayarc-memory** to check if `weekly-summary-current.json` exists. If it does **not** exist, this is a **bootstrap weekly run** — override the "Pure distillation" rule and query **Work IQ** for the last **14 days** of sent emails, Teams messages, meetings, and edited documents to supplement any sparse daily profiles. Label this data as bootstrap context in the synthesis step.

Via **dayarc-memory**, read:
- All files in `daily/` directory (up to 5 daily profiles, Mon–Fri)
- `weekly-summary-prev.json` (if exists)
- `monthly-summary.json` (if exists)

Handle missing files gracefully (bootstrap).

## Step 2: SYNTHESIZE

Run skills in this order:
1. **summarize_period** — roll up all daily profiles into a weekly summary. If weekly-summary-prev exists, absorb its unresolved stuck items.
2. **learn_user_profile** — update profile with the week's accumulated learning.

Produce brief sections:
- **A. Themes** — 3–5 work themes with effort_share (sum ~1.0) and progress notes.
- **B. Accomplishments** — ≤8 completed items (merged PRs, resolved threads, milestones). Deduplicate.
- **C. Stuck** — ≤5 items unfinished for 2+ days, with days_carried count.
- **D. Next Week** — 3–5 suggested focus areas from momentum + carryover + stuck.

## Step 3: WRITE (Memory Lifecycle)

Via **dayarc-memory**, execute in this exact order:
1. If `weekly-summary-prev.json` exists, archive it to `weekly-archive/week-{date}.json`.
2. If `weekly-summary-current.json` exists, move it to `weekly-summary-prev.json`.
3. Write new `weekly-summary-current.json` with this week's summary.
4. Delete all files in `daily/` (purge daily profiles — they're now absorbed into weekly).
5. Write `runs/{today}-weekly.json` run tag.

## Step 4: DELIVER

Via **dayarc-deliver**:
- Render `weekly.hbs` template with brief data.
- Subject: `📊 Weekly — Week of {Monday's date}`
- Send email to self via Outlook COM.

**Graceful degradation:** If daily profiles are sparse, note coverage gaps and continue with available data.
