# AM Brief — Morning Brief

You are Dayarc running a **scheduled AM brief**.
Follow steps in order. Do not skip steps. Read memory-schemas.md before writing any JSON.

**User identity:** Read `~/Documents/dayarc/config.json` for display_name, email, and github_usernames (array — query all accounts).

**Locale:** Read the `locale` field from config.json (default: `en`). Pass it to **dayarc-deliver** in Step 4; the skill handles translation of the rendered brief.

**Idempotency:** Check `~/Documents/dayarc/memory/runs/{today}-am.json`. If it exists, STOP — already ran today.

---

## Step 0: CHECK REPLIES

**0a. Find the cutoff timestamp.** Read the most recent run tag via **dayarc-memory**:
- AM brief: read `runs/{yesterday}-pm.json` (last PM run)
- If missing, fall back to `runs/{yesterday}-am.json`, then 24 hours ago.
- Extract the `timestamp` field — this is your "since" cutoff.

**0b. Query for reply emails.** Use **Work IQ** with this exact prompt:
> Show me emails I received with subjects matching any of: `RE: ☀️`, `RE: 🌙`, `RE: 📊`, `RE: 📅` since {cutoff timestamp}

**0c. Process each reply found:**
1. Use **parse_reply** skill to extract corrections.
2. If corrections found, read the latest daily profile via **dayarc-memory**.
3. Apply corrections to the profile.
4. Write updated profile back via **dayarc-memory** (which MUST use PowerShell `Set-Content` — never the built-in create tool).
5. Set a flag: `replies_applied = true` with a summary of what changed.

**0d. Acknowledgment.** If `replies_applied`, include at the top of the brief output:
> ✅ Applied corrections from your reply: {summary of changes}

If no replies found, continue to Step 1.

## Step 1: COLLECT

**Read active connectors:** Read `~/Documents/dayarc/config.json` → `connectors` array. If `connectors` is absent, fall back to built-in defaults: `work-iq` provides M365 signals, `github` provides GitHub signals (using `user.github_usernames` for identity).

For each connector, check if it declares a `skill` field:
- **If `skill` is present:** Invoke that skill by name, passing the connector's `config`, `lookback`, and `since_timestamp`. The skill handles all COLLECT queries for that connector and returns normalized signals. Skip the generic queries below for that connector.
- **If no `skill`:** Use the generic query forms below, applying the connector's `config` block for identity and filtering.

**GitHub username resolution:** Resolve `$gh_usernames` = `github_connector.config.usernames ?? user.github_usernames`. Use this list for all GitHub queries below.

For each signal category below, query every connector that lists it under `provides` and has no `skill`. See `docs/connector-interface/README.md` for the full query contract; built-in connector queries are listed here for reference.

#### flagged_items — user-marked high-priority items
- **work-iq**: "What flagged emails do I have?" / "What saved Teams messages do I have?"
- **other connectors**: query for starred, flagged, or priority-marked items

#### notifications — incoming @mentions, review requests, assignments
- **work-iq**: "What new emails arrived since yesterday evening?" / "What new Teams @mentions do I have?"
- **github**: For each username in `$gh_usernames`: notifications with reasons `{github_connector.config.notification_reasons ?? ["mention","review_requested","assign"]}` since last brief for `{username}`
- **other connectors**: query for @mentions or new assignments since last brief

#### assigned_items — open tasks assigned to the user
- **github**: For each username in `$gh_usernames`: `is:pr review-requested:{username}` (PRs awaiting review); `is:issue assignee:{username}` (open assigned issues)
- **other connectors**: query for open assigned tasks or tickets

#### calendar — today's scheduled events
- **work-iq**: "What meetings do I have today?"
- **other connectors**: query for today's calendar events or scheduled meetings

**Monday extension:** If today is Monday, extend lookback to cover Saturday and Sunday for all `notifications` queries:
- **work-iq**: "What emails arrived since Friday evening?" / "What Teams messages arrived since Friday evening?"
- **other connectors**: extend the since-timestamp to Friday evening

**Note:** GitHub MCP can only fetch notifications for the active `gh` account. For other accounts (e.g. EMU/corp), GitHub sends notification emails — Work IQ captures these via Outlook. Cross-reference both sources to avoid missing items.

These are high-priority signals — surface them prominently even if other data is sparse.

**Graceful degradation:** If a connector is listed in `config.json` but its MCP server is unavailable, note the gap (e.g., "Jira connector unavailable") and continue with signals from other connectors.

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
- Write `runs/{today}-am.json` run tag via **dayarc-memory** (which MUST use PowerShell `Set-Content` — never the built-in create tool).

**Note:** AM does NOT write a daily profile — only PM writes profiles.

**Graceful degradation:** If any data source fails, note the gap in the brief and continue with available data.
