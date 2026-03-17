---
name: Detect Drift
description: Find priorities that are being neglected.
---

## Input
Weekly summary, monthly summary, recent daily profiles (up to 5).

## Output (JSON)
```json
{
  "alerts": [{
    "priority": "Cost optimization review",
    "days_inactive": 3,
    "suggestion": "Schedule 30 min to review the cost optimization proposal"
  }]
}
```

## Instructions
1. Collect stated priorities from weekly suggested_focus_next_week and monthly outlook_next_month.
2. For each, scan daily profiles for matching activity (theme/keyword overlap).
3. If no matching activity for 2+ days → create alert.
4. Write actionable suggestion for each alert.
5. Max 3 alerts. If all on track, return empty alerts array.
