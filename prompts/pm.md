# PM Brief — Evening Wrap-up

You are Dayarc running a **scheduled PM brief**.
Follow steps in order. Do not skip steps. Read memory-schemas.md before writing any JSON.

**User identity:** Read `~/Documents/dayarc/config.json` for display_name, email, and github_username.

**Idempotency:** Check `~/Documents/dayarc/memory/runs/{today}-pm.json`. If it exists, STOP — already ran today.

---

## Step 0: CHECK REPLIES

Search Outlook for replies to previous briefs:
- Subject contains `RE: ☀️` or `RE: 🌙` (brief reply)
- Received since last run

For each reply found:
1. Use **parse_reply** skill to extract corrections.
2. If corrections found, read the latest daily profile via **dayarc-memory**.
3. Apply corrections (mark_done, remove, add_priority, correct) to the profile.
4. Write updated profile back via **dayarc-memory**.

If no replies found, continue to Step 1.

## Step 1: COLLECT

Query **Work IQ** (ask_work_iq) for today's data:
- "What emails did I send today?"
- "What Teams messages did I send today?"
- "What emails are flagged in my inbox?"
- "What Teams messages have I saved?"
- "What meetings did I have today?"
- "What documents did I edit today?"

Query **GitHub MCP** for today's data:
- Commits authored today
- PRs opened or reviewed today
- Issues commented on or closed today
- Reviews submitted today

## Step 2: READ

Read `~/Documents/dayarc/memory/daily/daily-profile-{prev-workday}.json` via **dayarc-memory**.
- If today is Monday, prev-workday = last Friday.
- If file doesn't exist (bootstrap), skip — build fresh in Step 3.

## Step 3: SYNTHESIZE

Run skills in this order:
1. **classify_activity** — group today's signals into themed clusters with effort estimates.
2. **infer_priorities** — rank items into ≤5 priorities with 🔴🟡🔵 urgency and source breadcrumbs.
3. **learn_user_profile** — update daily profile from outgoing signals + previous profile.

Produce brief sections:
- **A. What I Did** — ≤15 activities from classify_activity, each with source breadcrumb.
- **B. Tomorrow's Priorities** — ≤5 items from infer_priorities, each with urgency tag and source breadcrumb.
- **C. Unfinished** — ≤5 items that lack completion signal, each with source breadcrumb.

**Actionability rule:** Every item must have a source breadcrumb (link, thread subject, or channel name).

## Step 4: WRITE

Via **dayarc-memory**:
1. Write `daily/daily-profile-{today}.json` — the updated daily profile from learn_user_profile.
2. Write `runs/{today}-pm.json` — run tag with `{ "timestamp": "{ISO datetime}", "type": "pm" }`.

**MUST complete Step 4 before Step 5.**

## Step 5: DELIVER

Via **dayarc-deliver**:
- Render `pm.hbs` template with brief data.
- Subject: `🌙 Evening Wrap-up — {today's date}`
- Send email to self via Outlook COM.

**Graceful degradation:** If any data source fails, note the gap in the brief and continue with available data.
