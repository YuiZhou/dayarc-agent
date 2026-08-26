# Dayarc — Technical Design

**Status:** Final | **Date:** 2026-03-16 | **Spec:** [spec.md](./spec.md)

## 1. Architecture

Copilot CLI is the agent. Three portable layers:

```
Agent Package (installed)                      User Data ~/Documents/dayarc/ (portable, OneDrive-synced)
┌──────────────────────────────────┐           ┌──────────────────────────────┐
│  skills/       16 skill defs     │           │  memory/    JSON files       │
│  prompts/      4 plan files      │           │  config.json identity+prefs  │
│  templates/    8 brief templates │           └──────────────────────────────┘
│  memory-schemas.md               │
│  mcp.json      signal connectors │           Scheduler (optional, machine-specific)
│  docs/         connector guides  │           scheduler.ps1 + OS task registration
└──────────────────────────────────┘
```

| Component | Provider | Auth |
|-----------|----------|------|
| Agent + LLM | Copilot CLI (GPT-5.4) | `gh auth login` |
| M365 data | Work IQ MCP | Signed-in M365 |
| GitHub data | GitHub MCP | `gh auth token` |
| Memory | JSON in `~/Documents/dayarc/memory/` | — |
| Email | Outlook COM via shell | Signed-in Outlook |

**Portability:** User data lives in `~/Documents/dayarc/` — auto-synced across corp machines via OneDrive/SharePoint. Install agent on new machine → run `irm .../setup.ps1 | iex` → `gh auth login` → works. Agent code + user data = Markdown + JSON (cross-platform). Only scheduler + Outlook COM are platform-specific.

The COLLECT step (Step 1 in `pm.md` and `am.md`) is connector-agnostic — any MCP server can be plugged in as a signal source. See [docs/connector-interface/README.md](./docs/connector-interface/README.md) for the interface spec and connector setup guide.

## 1b. Install & Upgrade

**Install:** `irm https://raw.githubusercontent.com/YuiZhou/dayarc-agent/main/setup.ps1 | iex`

`setup.ps1` flow: preflight (git, gh auth, Copilot CLI, Outlook) → clone `~/.dayarc-agent/` → register with `~/.copilot/` → prompt config → offer scheduler → done.

**Upgrade (conversational):** User says "Update your skills" → `dayarc-upgrade` skill runs `git fetch` + `git pull --ff-only` in `~/.dayarc-agent/`, copies updated files to `~/.copilot/`.

**Upgrade (re-run setup):** `irm .../setup.ps1 | iex` detects existing `.git` → `git pull`, existing `config.json` → skip prompts, existing scheduler → skip.

**Uninstall:** `setup.ps1 -uninstall` removes scheduler + agent dir. User data preserved.

## 2. Execution Modes

| Mode | Trigger | Email | Memory | Run tag |
|------|---------|-------|--------|---------|
| **Scheduled** | scheduler.ps1 | ✅ | ✅ | ✅ |
| **Conversational** | User asks in CLI | ❌ terminal | ❌ | ❌ |
| **Conversational + explicit** | "send it" / "save" | if asked | if asked | ❌ |

Scheduled = authoritative. Conversational = preview by default. Dry run = conversational with no overrides.

## 3. Plans

PM/AM begin with **Step 0: CHECK REPLIES** — parse email reply corrections → update daily profile. Weekly/Monthly skip (run after PM).

**PM (8 PM):**
```
0. CHECK REPLIES  Parse brief reply corrections → update daily profile
1. COLLECT    Work IQ (sent, Teams sent, flagged, saved, meetings, docs) + GitHub (commits, PRs, issues, reviews)
2. READ       daily-profile-{prev-date} (skip on bootstrap)
3. SYNTHESIZE classify_activity → infer_priorities → write_impact_summary → learn_user_profile
             Produce: A."Impact Highlights"(2–5) B."Priorities"(≤5) C."Unfinished"(≤5) + source breadcrumbs
4. WRITE      daily-profile-{today}.json + run tag
5. DELIVER    deliver to configured targets (email, github-issue, etc.)
```

**AM (8 AM):**
```
0. CHECK REPLIES  Parse corrections → update daily profile
1. COLLECT    Work IQ (flagged, saved, new emails/mentions, calendar) + GitHub (notifications, reviews, issues)
             Monday: extend since to Sat+Sun
2. READ       daily-profile-{latest} + weekly-current + weekly-prev + monthly
3. SYNTHESIZE infer_priorities + filter_signals + detect_drift + learning from profile
             Produce: A."Today's Plan"(≤8, 🔴🟡🔵) B."Learning"(3–5) C."Signals"(≤10) D."You May Forget"(≤3)
4. DELIVER    deliver to configured targets
```

**Weekly (Friday 8 PM, after PM):** Pure distillation — no raw data.
```
1. READ       all 5 dailies + weekly-prev + monthly
2. SYNTHESIZE summarize_period → write_impact_summary → learn_user_profile
             Produce: A."Themes"(3–5) B."Impact Highlights"(2–5) C."Stuck"(≤5) D."Next Week"(3–5)
3. WRITE      absorb prev → archive → rotate → write new → purge dailies
4. DELIVER    deliver to configured targets
```

**Monthly (Last Workday, after Weekly):** Pure distillation — no raw data.
```
1. READ       weekly-archive/ + weekly-current + weekly-prev + prev monthly
2. SYNTHESIZE summarize_period → write_impact_summary → learn_user_profile
             Produce: A."Time Allocation" B."Impact Highlights"(3–6) C."Stuck" D."Learning" E."Next Month"(3–5)
3. WRITE      absorb prev month → overwrite monthly → purge old weekly-archive
4. DELIVER    deliver to configured targets
```

**Friday ordering:** PM → Weekly → Monthly (if last workday).

## 4. Skills

| Skill | Output | Purpose |
|-------|--------|---------|
| `classify_activity` | `{ groups[{ theme, activities[{desc, source_breadcrumb}], effort }] }` | Group signals into themes |
| `infer_priorities` | `{ priorities[{ desc, source_breadcrumb, urgency }] }` | Rank 🔴🟡🔵 |
| `learn_user_profile` | `DailyProfile` (§5) | Update focus, interests, contacts |
| `filter_signals` | `{ signals[{ desc, source_breadcrumb, relevance, pass_reason }] }` | Relevance filter; flags/saves/@mentions always pass |
| `detect_drift` | `{ alerts[{ priority, days_inactive, suggestion }] }` | Priorities inactive 2+ days |
| `summarize_period` | `{ themes[], accomplishments[], stuck[], focus_next[] }` | Weekly/monthly rollup |
| `parse_reply` | `{ corrections[{ action, target, detail }] }` | Extract corrections from reply text |
| `write_impact_summary` | `{ impact_summaries[{ situation, task, action, result, impact }] }` | Turn evidence into STAR-style outcome narratives |
| `dayarc-memory` | Read/write JSON | File I/O for memory directory |
| `dayarc-deliver` | Delivery summary | Render templates + deliver to configured targets (email, github-issue, etc.) |
| `dayarc-upgrade` | Status message | Check for / apply agent updates from GitHub |
| `dayarc-report-issue` | GitHub issue URL | Auto-fill and file bug/feature on Dayarc repo (user confirms) |
| `dayarc-review-prep` | Terminal output | Generate performance review / 1:1 talking points from 1–6 monthly summaries |

## 4b. Delivery Targets

The DELIVER step is pluggable — briefs can be sent to multiple targets per `config.json → delivery`.

| Target | Format | Mechanism | Idempotency |
|--------|--------|-----------|-------------|
| `email` | HTML (`.hbs`) | Outlook COM | Check Sent Items by subject |
| `github-issue` | Markdown (`.md.hbs`) | `gh issue create` | Hidden marker `<!-- dayarc:brief={type} period={period} -->` |

**Config:**
```json
{
  "delivery": [
    { "target": "email", "briefs": ["pm", "am", "weekly", "monthly"] },
    { "target": "github-issue", "briefs": ["weekly"],
      "config": { "repo": "owner/repo", "labels": ["weekly-brief"] } }
  ]
}
```

Default (no `delivery` field): email-only for all brief types. Targets are independent — partial failures don't block other targets.

## 5. Memory

JSON in `~/Documents/dayarc/memory/`. Agent references `memory-schemas.md` before writing.

```
daily/daily-profile-{YYYY-MM-DD}.json   # Up to 5 (Mon–Fri)
weekly-summary-current.json
weekly-summary-prev.json
weekly-archive/                         # Current month only
monthly-summary.json
monthly-archive/                        # Up to 6 months (for review prep)
runs/{date}-{type}.json                 # Idempotency (scheduled only)
```

**Daily** — `focus_areas[{label, confidence, last_seen}]`, `learning_interests[{topic, trajectory, first_seen}]`, `key_contacts[{name, email, interaction_count}]`, `active_threads[{id, description, status, days_open}]`, `impact_summaries[]`, `priorities_today[]`, `unfinished[]`

**Weekly** — `themes[{label, effort_share, progress}]`, `accomplishments[]`, `impact_summaries[]`, `stuck_items[{description, days_carried}]`, `suggested_focus_next_week[]`, `absorbed_from_previous[]`

**Monthly** — `time_allocation[{area, share, trend}]`, `accomplishments[]`, `impact_summaries[]`, `persistently_stuck[{description, weeks_stuck}]`, `learning_progress[{topic, trajectory, recommendation}]`, `outlook_next_month[]`, `absorbed_from_previous[]`. Archived to `monthly-archive/{YYYY-MM}.json`; up to 6 months retained for **review prep**.

**Memory correction** — Conversation defaults to the latest daily profile unless a period is named. Email replies
update the exact daily, weekly, or monthly memory represented by the original brief; priorities and quality feedback
remain daily-only.

## 6. Scheduler (Optional)

```powershell
param([string]$trigger)  # "am" or "pm"
$profile = "~/Documents/dayarc"; $agent = "~/.dayarc-agent"
if ($trigger -eq "pm") {
    copilot-cli --prompt "$agent/prompts/pm.md" --cwd $profile
    if ((Get-Date).DayOfWeek -eq "Friday") { copilot-cli --prompt "$agent/prompts/weekly.md" --cwd $profile }
    if (Is-LastWorkday (Get-Date)) { copilot-cli --prompt "$agent/prompts/monthly.md" --cwd $profile }
}
if ($trigger -eq "am") { copilot-cli --prompt "$agent/prompts/am.md" --cwd $profile }
```

Only for automated runs. Briefs also triggerable conversationally.

## 7. Auth & Security

| Rule | Implementation |
|------|---------------|
| Read-only externally | Only writes = memory files + email to self |
| Idempotent | Run tag before send (scheduled only) |
| Data boundary | Within Microsoft boundary (M365 + GitHub Copilot API) |
| No credentials stored | Runtime auth via `gh auth` / M365 session |

## 8. Phases

| Phase | Scope |
|-------|-------|
| **0** | PoC: Copilot CLI non-interactive execution, file I/O, skill consumption |
| **1** | Agent package + user data, PM brief E2E, manual run |
| **2** | AM/Weekly/Monthly, memory lifecycle, memory correction |
| **3** | Scheduler, idempotency, conversational triggers + dry-run, portability test |
| **4** | Prompt tuning, skill refinement |

## 9. Risks

| Risk | Mitigation |
|------|-----------|
| Non-interactive CLI unproven | Phase 0 PoC. Fallback: stdin pipe. |
| Agent deviates from plan | Detailed step instructions. Phase 1 manual validation. |
| Memory schema corruption | `memory-schemas.md` reference. |
| Reply parsing unreliable | `parse_reply` skill with examples. Non-actionable → ignored. |
| Conversational trigger writes memory | Default = no writes. Explicit request required. |
