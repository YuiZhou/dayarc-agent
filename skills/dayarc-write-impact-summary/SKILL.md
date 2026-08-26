---
name: Write Impact Summary
description: Turn work evidence into concise Situation-Task-Action-Result-Impact narratives without inventing outcomes.
---

## Input

```json
{
  "period": "daily | weekly | monthly",
  "signals": [],
  "themes": [],
  "activities": [],
  "accomplishments": [],
  "prior_impact_summaries": []
}
```

Inputs may come directly from collected signals for a daily summary, from daily profiles for a weekly summary, or
from weekly summaries for a monthly summary.

## Output (JSON)

```json
{
  "impact_summaries": [
    {
      "title": "Hardened GitHub brief delivery",
      "situation": "Brief delivery could resolve the wrong repository when another GitHub account was active.",
      "task": "Make repository selection authoritative across multi-account environments.",
      "action": "Added account-aware repository resolution and explicit failure when the configured repository is unavailable.",
      "result": "Briefs now stop instead of being redirected to a different repository.",
      "impact": "Protects private work summaries from being delivered to the wrong audience.",
      "status": "completed",
      "source_breadcrumbs": ["github.com/owner/repo/pull/123"]
    }
  ]
}
```

`result` and `impact` are optional when the available evidence does not support them.

## Instructions

1. Build summaries around meaningful outcomes, decisions, risks reduced, people unblocked, or progress toward a
   goal. Do not create one summary per email, commit, repository, meeting, or chat thread.
2. Merge related evidence into one narrative even when it comes from different connectors or repositories.
3. Use a compact STAR-style structure:
   - `situation` — the problem, need, constraint, or goal that made the work relevant.
   - `task` — the responsibility or intended change.
   - `action` — the concrete work the user performed. Use strong verbs and name the object changed.
   - `result` — an outcome directly supported by evidence, such as merged, shipped, approved, resolved, validated,
     documented, decided, or unblocked.
   - `impact` — why the result matters to users, reliability, delivery, cost, security, quality, or team velocity.
4. Never invent metrics, business impact, completion, causality, or stakeholder benefit. If evidence only shows
   activity, omit `result` and `impact`, set `status` to `"in_progress"`, and make the action describe concrete
   progress rather than claiming success.
5. Use `status` values:
   - `completed` — a completion or terminal result is explicit in the evidence.
   - `advanced` — a review, decision, milestone, or meaningful intermediate result is explicit.
   - `in_progress` — work occurred but no result is yet observable.
6. Every summary must include at least one `source_breadcrumbs` entry. Deduplicate breadcrumbs and retain the most
   useful links, issue/PR IDs, meeting titles, or thread subjects. Maximum 4 breadcrumbs per summary.
7. Prefer 2–5 summaries for daily and weekly periods and 3–6 for monthly periods. Rank by observed impact,
   completion, effort, and strategic relevance.
8. For weekly and monthly rollups, synthesize across prior `impact_summaries`; do not merely concatenate or repeat
   daily/weekly wording. Describe the larger arc and deduplicate the same outcome across periods.
9. Keep each field to one concise sentence. The full summary should be understandable without opening the source,
   while the breadcrumbs preserve traceability.
