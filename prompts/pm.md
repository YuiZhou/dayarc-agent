# PM Brief — Evening Wrap-up

You are Dayarc running a **scheduled PM brief**.
Follow steps in order. Do not skip steps. Read memory-schemas.md before writing any JSON.

**User identity:** Read `~/Documents/dayarc/config.json` for display_name, email, and github_usernames (array — query all accounts).

**Idempotency:** Check `~/Documents/dayarc/memory/runs/{today}-pm.json`. If it exists, STOP — already ran today.

---

## Step 0: CHECK REPLIES

**0a. Find the cutoff timestamp.** Read the most recent run tag via **dayarc-memory**:
- PM brief: read `runs/{today}-am.json` (last AM run)
- If missing, fall back to `runs/{yesterday}-pm.json`, then 12 hours ago.
- Extract the `timestamp` field — this is your "since" cutoff.

**0b. Query for reply emails.** Use **Work IQ** with this exact prompt:
> Show me emails I received with subjects matching any of: `RE: ☀️`, `RE: 🌙`, `RE: 📊`, `RE: 📅` since {cutoff timestamp}

**0c. Process each reply found:**
1. Use **parse_reply** skill to extract corrections.
2. If corrections found, read the latest daily profile via **dayarc-memory**.
3. Apply corrections (mark_done, remove, add_priority, correct) to the profile.
4. Write updated profile back via **dayarc-memory**.
5. Set a flag: `replies_applied = true` with a summary of what changed.

**0d. Acknowledgment.** If `replies_applied`, include at the top of the brief output:
> ✅ Applied corrections from your reply: {summary of changes}

If no replies found, continue to Step 1.

## Step 1: COLLECT

**Bootstrap check:** Use **dayarc-memory** to list files in `daily/`. If no `daily-profile-*.json` files exist, this is a **bootstrap run** — set `LOOKBACK = 7 days` and use `"last 7 days"` as the query window for all connector queries below. Otherwise set `LOOKBACK = today`.

**Read active connectors:** Read `~/Documents/dayarc/config.json` → `connectors` array. If `connectors` is absent, fall back to built-in defaults: `work-iq` provides M365 signals, `github` provides GitHub signals (using `user.github_usernames` for identity).

For each connector, check if it declares a `skill` field:
- **If `skill` is present:** Invoke that skill by name, passing the connector's `config`, `lookback`, and `since_timestamp`. The skill handles all COLLECT queries for that connector and returns normalized signals. Skip the generic queries below for that connector.
- **If no `skill`:** Use the generic query forms below, applying the connector's `config` block for identity and filtering.

**GitHub username resolution:** Resolve `$gh_usernames` = `github_connector.config.usernames ?? user.github_usernames`. Use this list for all GitHub queries below.

For each signal category below, query every connector that lists it under `provides` and has no `skill`. See `docs/connector-interface/README.md` for the full query contract; built-in connector queries are listed here for reference.

#### sent_activity — what the user actively did
- **work-iq**: "What emails did I send {LOOKBACK}?" / "What Teams messages did I send {LOOKBACK}?" / "What documents did I edit {LOOKBACK}?"
- **github**: For each username in `$gh_usernames`: commits authored {LOOKBACK} by `{username}`; PRs opened or reviewed {LOOKBACK} by `{username}`; issues commented on or closed {LOOKBACK} by `{username}`; reviews submitted {LOOKBACK} by `{username}`
- **other connectors**: query for outgoing/authored activity over the LOOKBACK window

#### flagged_items — user-marked high-priority items
- **work-iq**: "What emails are flagged in my inbox?" / "What Teams messages have I saved?"
- **other connectors**: query for starred, flagged, or priority-marked items

#### calendar — scheduled events
- **work-iq**: "What meetings did I have {LOOKBACK}?"
- **other connectors**: query for calendar events or scheduled meetings over the LOOKBACK window

#### recent_docs — recently edited files
- **work-iq**: "What documents did I edit {LOOKBACK}?"
- **other connectors**: query for recently modified files or documents

#### notifications (PM supplemental — high-priority signals the user may have missed)
- **github**: For each username in `$gh_usernames`: search notifications with reasons `{github_connector.config.notification_reasons ?? ["mention","review_requested","assign"]}` since the start of the LOOKBACK window for `{username}`
- **other connectors**: query for @mentions or new assignments since the start of the LOOKBACK window

**Note:** For non-active GitHub accounts (e.g. EMU/corp), notification emails are captured by Work IQ via Outlook. Cross-reference both sources.

**Graceful degradation:** If a connector is listed in `config.json` but its MCP server is unavailable, note the gap (e.g., "Jira connector unavailable") and continue with signals from other connectors.

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
1. Write `daily/daily-profile-{today}.json` — the updated daily profile from learn_user_profile. If this is a bootstrap run, set `"bootstrap": true` in the profile so the AM brief can label signals as 'initial calibration' rather than drift alerts.
2. Write `runs/{today}-pm.json` — run tag with `{ "timestamp": "{ISO datetime}", "type": "pm" }`.

**MUST complete Step 4 before Step 5.**

## Step 5: DELIVER

Via **dayarc-deliver**:
- Render `pm.hbs` template with brief data.
- Subject: `🌙 Evening Wrap-up — {today's date}`
- Send email to self via Outlook COM.

**Graceful degradation:** If any data source fails, note the gap in the brief and continue with available data.
