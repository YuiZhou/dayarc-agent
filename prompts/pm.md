# PM Brief — Evening Wrap-up

You are Dayarc running a **scheduled PM brief**.
Follow steps in order. Do not skip steps. Read memory-schemas.md before writing any JSON.

**User identity:** Read `~/Documents/dayarc/config.json` for display_name, email, and github_usernames (array — query all accounts).

**Locale:** Read the `locale` field from config.json (default: `en`). Pass it to **dayarc-deliver** in Step 5; the skill handles translation of the rendered brief.

**Idempotency:** Check `~/Documents/dayarc/memory/runs/{today}-pm.json`. If it exists, STOP — already ran today.

---

## Step 0: CHECK REPLIES

**0a. Find the cutoff timestamp.** Read the most recent run tag via **dayarc-memory**:
- PM brief: read `runs/{today}-am.json` (last AM run)
- If missing, fall back to `runs/{yesterday}-pm.json`, then 12 hours ago.
- Extract the `timestamp` field — this is your "since" cutoff.

**0b. Query for inbox signals.** Use **Work IQ** to fetch two categories of emails since {cutoff timestamp}:

1. **Replies to Dayarc briefs** — emails where the subject starts with any of these reply prefixes (`RE:`, `AW:`, `Antw:`, `Rép:`) followed by any of these emoji: `☀️`, `🌙`, `📊`, `📅`
2. **Self-sent memos** — emails the user sent to themselves (From: and To: are both the user's own email address). These are treated as self-correction notes and automatically tagged as high-priority.

Collect both sets and pass each to Step 0c.

**0c. Process each email found:**
1. Use **parse_reply** skill to analyze the full email body in natural language. Pass the **full raw email body** (including any HTML) — the skill handles HTML stripping, quoted-text removal, and signature removal automatically before extracting intent.
2. If the parsed result contains corrections, read the latest daily profile via **dayarc-memory**.
3. For each correction in the `parse_reply` output, apply the corresponding profile update. The `action` field in each correction (produced by parse_reply's NL analysis, not by the user) determines what to change:
   - `mark_done` → find the matching item in `active_threads` (by keyword overlap on `description`) and set `status` to `"done"`; remove matching entries from `priorities_today` and `unfinished`.
   - `remove` → remove the matching item from `priorities_today` and `unfinished` arrays; if found in `active_threads`, set `status` to `"dropped"`.
   - `add_priority` → append a new entry to `priorities_today`: `description` = correction target, `urgency` = `"🟡 soon"`, `source_breadcrumb` = `"User reply"` (or `"Self-memo"` for self-sent emails).
   - `correct` → find the matching item across `priorities_today`, `unfinished`, and `active_threads` and update its `description` with the corrected value.
4. If the parsed result contains quality signals (sentiment positive or negative), write the most recent one to `profile.feedback` (overwrite any existing entry; if multiple, combine into a single detail string).
5. Write the updated profile back via **dayarc-memory** (which MUST use PowerShell `Set-Content` — never the built-in create tool).
6. Set a flag: `replies_applied = true` with a summary of what changed.

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

Via **dayarc-memory** (which MUST use PowerShell `Set-Content` — never the built-in create tool):
1. Write `daily/daily-profile-{today}.json` — the updated daily profile from learn_user_profile. If this is a bootstrap run, set `"bootstrap": true` in the profile so the AM brief can label signals as 'initial calibration' rather than drift alerts.
2. Write `runs/{today}-pm.json` — run tag with `{ "timestamp": "{ISO datetime}", "type": "pm" }`.

> ⚠️ **Step 4 writes memory ONLY. Do NOT render or send email in this step.**
> Email delivery happens exclusively in Step 5. Never combine Step 4 and Step 5 into a single shell block.

**MUST complete Step 4 before Step 5.**

## Step 5: DELIVER

> ⚠️ **This is the ONLY step that sends email. Never send email in any other step.**

Via **dayarc-deliver**:
- Render `pm.hbs` template with brief data.
- Subject: `🌙 Evening Wrap-up — {today's date}`
- Send email to self via Outlook COM.

**Graceful degradation:** If any data source fails, note the gap in the brief and continue with available data.
