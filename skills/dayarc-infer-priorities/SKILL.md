---
name: Infer Priorities
description: Rank items by urgency into a priority list with source breadcrumbs.
---

## Input
Flagged emails, saved Teams messages, high-effort activities, meetings, carryover items, calendar.

## Output (JSON)
```json
{
  "priorities": [{
    "description": "Review auth token refresh PR",
    "source_breadcrumb": "github.com/org/repo/pull/1234",
    "urgency": "🔴 urgent"
  }]
}
```

## Instructions
1. Rank order: Outlook flags/Teams saves → direct @mentions → carryover → calendar → high-effort activities → inbound requests.
2. Each priority: one line describing *what* to do, with source breadcrumb. **Write all descriptions in the language specified by `config.preferences.locale` (default: `en`). For `zh`: use Simplified Chinese professional tone.**
3. Assign urgency: 🔴 urgent = today/overdue, 🟡 soon = this week, 🔵 when-free = can wait.
4. PM brief: max 5. AM brief: max 8.
