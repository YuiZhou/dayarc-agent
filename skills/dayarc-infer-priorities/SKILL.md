---
name: Infer Priorities
description: Rank items by urgency into a priority list with source breadcrumbs.
---

## Input
Flagged emails, saved Teams messages, direct @mentions, GitHub review requests/assignments, high-effort activities, meetings, carryover items, calendar.

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
1. Rank order: Outlook flags/Teams saves → direct @mentions and GitHub review requests/assignments → carryover → calendar → high-effort activities → inbound requests.
2. For AM briefs, still-open flagged or saved items from yesterday stay at the top of Today's Plan until cleared.
3. Each priority: one line describing *what* to do, with source breadcrumb.
4. Assign urgency: 🔴 urgent = today/overdue, 🟡 soon = this week, 🔵 when-free = can wait.
5. PM brief: max 5. AM brief: max 8.
