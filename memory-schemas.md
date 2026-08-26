# Memory Schemas Reference

> ⚠️ **IMPORTANT — File Write Method:**
> Always write memory files using **PowerShell shell commands** (`Set-Content` or `Out-File`).
> **Never use the Copilot CLI built-in `create` tool.** The `create` tool writes to the session sandbox (`~/.copilot/session-state/{id}/files/`) and files will **not** persist to `~/Documents/dayarc/memory/` — they are lost when the session ends.
>
> **Correct (shell):**
> ```powershell
> $memDir = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "dayarc\memory"
> $json | Set-Content (Join-Path $memDir "daily\daily-profile-2026-04-01.json") -Encoding UTF8
> ```
>
> **Wrong (create tool):** Do not call `create daily-profile-2026-04-01.json` — this goes to the session sandbox, not the filesystem.

**How to Use:** Before writing any memory file, read this document. Validate output matches the schema below.

---

## DailyProfile

**File:** `daily/daily-profile-{YYYY-MM-DD}.json`
**Written by:** PM brief (Step 4)
**Retained:** Up to 5 (Mon–Fri), purged on weekly rotation.

```json
{
  "date": "2026-03-14",
  "focus_areas": [
    {
      "label": "auth migration",
      "confidence": 0.85,
      "last_seen": "2026-03-14"
    }
  ],
  "learning_interests": [
    {
      "topic": "Rust async patterns",
      "trajectory": "rising",
      "first_seen": "2026-03-10"
    }
  ],
  "key_contacts": [
    {
      "name": "Jane Smith",
      "email": "jane@company.com",
      "interaction_count": 5
    }
  ],
  "active_threads": [
    {
      "id": "thread-pr-1234",
      "description": "Token refresh PR review",
      "status": "in_progress",
      "days_open": 3
    }
  ],
  "impact_summaries": [
    {
      "title": "Hardened GitHub brief delivery",
      "situation": "Brief delivery could resolve the wrong repository when another GitHub account was active.",
      "task": "Make repository selection authoritative across multi-account environments.",
      "action": "Added account-aware repository resolution and explicit failure for unavailable repositories.",
      "result": "Briefs now stop instead of being redirected to a different repository.",
      "impact": "Protects private work summaries from being delivered to the wrong audience.",
      "status": "completed",
      "source_breadcrumbs": ["github.com/owner/repo/pull/123"]
    }
  ],
  "priorities_today": [
    {
      "description": "Review auth token refresh PR",
      "source_breadcrumb": "github.com/org/repo/pull/1234",
      "urgency": "🔴 urgent"
    }
  ],
  "unfinished": [
    {
      "description": "Cost optimization proposal review",
      "source_breadcrumb": "Outlook: Re: Cost optimization review"
    }
  ],
  "feedback": {
    "sentiment": "negative",
    "detail": "too much noise in inbox section"
  }
}
```

### Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `date` | string (YYYY-MM-DD) | ✅ | Profile date |
| `focus_areas` | array | ✅ | Current work themes. Confidence 0–1, decays -0.1/day if unseen, removed at <0.1. New items start at 0.5. |
| `learning_interests` | array | ✅ | Topics the user is learning. Trajectory: "rising", "steady", "declining". |
| `key_contacts` | array | ✅ | People interacted with. Increment interaction_count per signal. |
| `active_threads` | array | ✅ | Open work items. Status: "in_progress", "waiting", "blocked". Increment days_open daily. |
| `impact_summaries` | array | Optional | 2–5 evidence-backed STAR-style narratives generated from the day's related signals. Required for newly written profiles; optional for backward compatibility. |
| `priorities_today` | array | ✅ | From infer_priorities output. |
| `unfinished` | array | ✅ | Items lacking completion signal. Each needs source_breadcrumb. |
| `feedback` | object | Optional | Quality signal from user's reply: `{ sentiment: "positive"\|"negative", detail: string }`. Written by parse_reply (Step 0) when a quality signal is detected; omitted if reply contained no quality signal. |

---

## WeeklySummary

**File:** `weekly-summary-current.json` (and `weekly-summary-prev.json`, `weekly-archive/*.json`)
**Written by:** Weekly brief (Step 3)
**Retained:** current + prev + archive (current month only).

```json
{
  "week_of": "2026-03-10",
  "themes": [
    {
      "label": "auth migration",
      "effort_share": 0.6,
      "progress": "Completed token refresh. Started session management."
    }
  ],
  "accomplishments": [
    "Merged PR #1234 — token refresh implementation",
    "Resolved flaky ARM CI pipeline"
  ],
  "impact_summaries": [
    {
      "title": "Completed token refresh rollout",
      "situation": "Authentication sessions needed a safer refresh path.",
      "task": "Finish and validate the token refresh implementation.",
      "action": "Implemented the refresh flow, addressed review feedback, and merged the change.",
      "result": "The token refresh path was merged and ready for rollout.",
      "impact": "Removes a blocker for the broader authentication migration.",
      "status": "completed",
      "source_breadcrumbs": ["github.com/org/repo/pull/1234"]
    }
  ],
  "stuck_items": [
    {
      "description": "Cost optimization proposal — waiting on finance review",
      "days_carried": 4
    }
  ],
  "suggested_focus_next_week": [
    "Finish session management rollout",
    "Address cost optimization feedback"
  ],
  "absorbed_from_previous": [
    "Cost optimization proposal (carried from prev week)"
  ],
  "brief_quality": {
    "rated": 3,
    "positive": 2,
    "negative": 1,
    "themes": ["too much noise in inbox"]
  }
}
```

### Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `week_of` | string (YYYY-MM-DD) | ✅ | Monday of the week |
| `themes` | array | ✅ | Work themes with effort_share (sum ~1.0) and progress narrative. |
| `accomplishments` | array | ✅ | Completed items. Deduplicated across days. |
| `impact_summaries` | array | Optional | 2–5 weekly narratives synthesized from daily impact summaries. Required for newly written summaries; optional for older memory. |
| `stuck_items` | array | ✅ | Unfinished 2+ days. days_carried = count of days item appeared. |
| `suggested_focus_next_week` | array | ✅ | 3–5 suggestions from momentum + stuck. |
| `absorbed_from_previous` | array | Optional | Unresolved items absorbed from previous week's summary. |
| `brief_quality` | object | Optional | Aggregated brief quality from `feedback` fields in daily profiles: `{ rated, positive, negative, themes[] }`. Omitted if no daily profiles had feedback this week. |

---

## MonthlySummary

**File:** `monthly-summary.json`
**Written by:** Monthly brief (Step 3)
**Retained:** 1, overwritten each month.

```json
{
  "month": "2026-03",
  "time_allocation": [
    {
      "area": "auth migration",
      "share": 0.45,
      "trend": "↓ decreasing"
    }
  ],
  "accomplishments": [
    "Shipped auth token refresh (PR #1234)",
    "Launched weekly team sync cadence"
  ],
  "impact_summaries": [
    {
      "title": "Advanced the authentication migration",
      "situation": "Authentication modernization remained the month's primary delivery goal.",
      "task": "Move token refresh and session management toward production readiness.",
      "action": "Shipped token refresh and started the session-management rollout.",
      "result": "One migration milestone shipped and the next entered rollout.",
      "impact": "Reduced remaining scope and created momentum toward completing the migration.",
      "status": "advanced",
      "source_breadcrumbs": ["github.com/org/repo/pull/1234", "Auth migration planning thread"]
    }
  ],
  "persistently_stuck": [
    {
      "description": "ARM CI pipeline stability",
      "weeks_stuck": 3
    }
  ],
  "learning_progress": [
    {
      "topic": "Rust async patterns",
      "trajectory": "rising",
      "recommendation": "Continue with tokio deep-dive"
    }
  ],
  "outlook_next_month": [
    "Complete session management rollout",
    "Start Q2 planning"
  ],
  "absorbed_from_previous": [
    "ARM CI pipeline (carried from prev month)"
  ],
  "brief_quality": {
    "rated": 12,
    "positive": 9,
    "negative": 3,
    "themes": ["too much noise in inbox", "priorities were off"]
  }
}
```

### Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `month` | string (YYYY-MM) | ✅ | Month identifier |
| `time_allocation` | array | ✅ | Top themes with share and trend (↑/→/↓). |
| `accomplishments` | array | ✅ | ≤10 items. Deduplicated across weeks. |
| `impact_summaries` | array | Optional | 3–6 monthly narratives synthesized from weekly impact summaries. Required for newly written summaries; optional for older memory and archives. |
| `persistently_stuck` | array | ✅ | Items stuck 2+ weeks. weeks_stuck = count. |
| `learning_progress` | array | ✅ | Topics with trajectory and recommendation. |
| `outlook_next_month` | array | ✅ | 3–5 focus areas. |
| `absorbed_from_previous` | array | Optional | Unresolved items from previous month. |
| `brief_quality` | object | Optional | Aggregated brief quality rolled up from weekly `brief_quality` fields: `{ rated, positive, negative, themes[] }`. Omitted if no weekly summaries had quality data. |

---

## Monthly Archive

**File:** `monthly-archive/{YYYY-MM}.json` (e.g., `monthly-archive/2026-03.json`)
**Written by:** Monthly brief (Step 3) — the previous `monthly-summary.json` is archived here before being overwritten.
**Retained:** Up to 6 months. Files older than 6 months are purged on each monthly rotation.
**Schema:** Same as `MonthlySummary` above.

This archive is the data source for the **dayarc-review-prep** skill, which reads 1–6 months to generate performance review talking points.

---

## Run Tags

**File:** `runs/{date}-{type}.json` (e.g., `runs/2026-03-14-pm.json`)
**Written by:** Each scheduled brief before sending email.
**Purpose:** Idempotency — if tag exists, brief already ran, skip.

```json
{
  "timestamp": "2026-03-14T20:00:00Z",
  "type": "pm"
}
```
