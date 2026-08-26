---
name: Classify Activity
description: Group raw activity signals into thematic clusters with effort estimates.
---

## Input
Raw signals from Work IQ + GitHub for the day.

## Output (JSON)
```json
{
  "groups": [{
    "theme": "auth migration",
    "activities": [{ "description": "Reviewed token refresh PR #1234", "source_breadcrumb": "github.com/org/repo/pull/1234" }],
    "effort": "high"
  }]
}
```

## Instructions
1. Scan all signals from the day.
2. Cluster by work theme (e.g., "auth migration", "team coordination", "code review").
3. Within each cluster, write one sentence per activity using a strong action verb and naming the object changed,
   reviewed, decided, or unblocked. Include an observed outcome when the signal explicitly provides one; otherwise
   describe concrete progress without claiming completion.
4. Every activity MUST have a `source_breadcrumb` — a link, thread subject, or channel name. If unavailable: "source unavailable".
5. **Teams meeting links** (`19:meeting_...@thread.v2`): these often break after the meeting ends. When a breadcrumb contains a meeting thread link, add a fallback — include the meeting title, date, and participant names so the user can locate the context manually. Mark the breadcrumb with `⚠️` to indicate it may not resolve.
6. Estimate effort per cluster: "high", "medium", or "low" relative to the day.
7. Max 15 activities total across all groups.
8. Keep this output evidence-oriented. Narrative synthesis and impact framing are handled by
   **dayarc-write-impact-summary** after classification.
