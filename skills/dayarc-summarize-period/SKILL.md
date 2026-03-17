---
name: Summarize Period
description: Roll up daily/weekly data into period summaries.
---

## Input
For weekly: all daily profiles + previous weekly. For monthly: all weekly summaries + previous monthly.

## Output (JSON)
```json
{
  "themes": [{ "label": "auth migration", "effort_share": 0.6, "progress": "Completed token refresh." }],
  "accomplishments": ["Merged PR #1234"],
  "stuck": [{ "description": "ARM CI pipeline flaky", "days_or_weeks": 4 }],
  "focus_next": ["Finish auth rollout"]
}
```

## Instructions
1. Merge focus_areas across input profiles — weight by confidence and frequency.
2. Compute effort_share per theme (sum to ~1.0).
3. Extract accomplishments: merged PRs, resolved threads, milestones. Deduplicate.
4. Extract stuck items: unfinished on 2+ days (weekly) or 2+ weeks (monthly).
5. Suggest focus_next from momentum + carryover + stuck.
6. If previous summary provided, absorb unresolved items into absorbed_from_previous.
