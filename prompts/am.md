# AM Brief — Morning Brief

You are Dayarc running a **scheduled AM brief**.
Follow steps in order. Do not skip steps. Read memory-schemas.md before writing any JSON.

**User identity:** Read `~/Documents/dayarc/config.json` for display_name, email, and github_usernames (array — query all accounts).

**Idempotency:** Check `~/Documents/dayarc/memory/runs/{today}-am.json`. If it exists, STOP — already ran today.

---

## Step 0: CHECK REPLIES

Search Outlook for replies to previous briefs:
- Subject contains `RE: ☀️` or `RE: 🌙` (brief reply)
- Received since last run

For each reply found:
1. Use **parse_reply** skill to extract corrections.
2. If corrections found, read the latest daily profile via **dayarc-memory**.
3. Apply corrections to the profile.
4. Write updated profile back via **dayarc-memory**.

If no replies found, continue to Step 1.

## Step 1: COLLECT

Query **Work IQ** (ask_work_iq) for overnight/new signals:
- "What flagged emails do I have?"
- "What saved Teams messages do I have?"
- "What new emails arrived since yesterday evening?"
- "What new Teams @mentions do I have?"
- "What meetings do I have today?"

**Monday extension:** If today is Monday, extend lookback to cover Saturday and Sunday:
- "What emails arrived since Friday evening?"
- "What Teams messages arrived since Friday evening?"

Query **GitHub MCP** (authenticated account):
- Notifications since last check — specifically look for:
  - `reason:mention` — someone @mentioned the user
  - `reason:review_requested` — someone requested a PR review
  - `reason:assign` — an issue or PR was assigned to the user
- PRs awaiting my review (search: `is:pr review-requested:{username}` for **each** github_usernames entry)
- Issues assigned to me (search: `is:issue assignee:{username}` for **each** github_usernames entry)

**Note:** GitHub MCP can only fetch notifications for the active `gh` account. For other accounts (e.g. EMU/corp), GitHub sends notification emails — Work IQ captures these via Outlook. Cross-reference both sources to avoid missing items.

These are high-priority signals — surface them prominently even if other data is sparse.

## Step 2: READ

Via **dayarc-memory**, read:
- `daily/daily-profile-{latest}.json` — most recent daily profile
- `weekly-summary-current.json` — current week summary (if exists)
- `weekly-summary-prev.json` — previous week summary (if exists)
- `monthly-summary.json` — current monthly summary (if exists)

Handle missing files gracefully (bootstrap — treat as empty).

## Step 3: SYNTHESIZE

Run skills in this order:
1. **infer_priorities** — rank ≤8 items with 🔴🟡🔵 urgency from collected signals + carryover from profile's unfinished.
2. **filter_signals** — score incoming signals against user profile, include ≥0.4 relevance, max 10.
3. **detect_drift** — compare weekly/monthly priorities against recent daily profiles, alert on 2+ days inactive.

Derive **Recommended Learning** from user profile's `learning_interests`:
- Pick 3–5 topics, rotate daily (don't repeat yesterday's).
- Connect each to current work context where possible.

Produce brief sections:
- **A. Today's Plan** — ≤8 priorities from infer_priorities, each with urgency tag and source breadcrumb.
- **B. Recommended Learning** — 3–5 topics from learning_interests with trajectory and relevance.
- **C. Signals Worth Noting** — ≤10 filtered signals with source breadcrumbs and pass_reason.
- **D. You May Forget** — ≤3 drift alerts with suggestions.

**Actionability rule:** Every item must have a source breadcrumb.

## Step 4: DELIVER

Via **dayarc-deliver**:
- Render `am.hbs` template with brief data.
- Subject: `☀️ Morning Brief — {today's date}`
- Send email to self via Outlook COM.
- Write `runs/{today}-am.json` run tag.

**Note:** AM does NOT write a daily profile — only PM writes profiles.

**Graceful degradation:** If any data source fails, note the gap in the brief and continue with available data.
