---
name: Filter Signals
description: Score incoming signals for relevance against user profile.
---

## Input
AM candidate signals: flagged emails, saved Teams messages, direct @mentions, GitHub review requests/assignments, new emails/messages, and user profile.

## Output (JSON)
```json
{
  "signals": [{
    "description": "Email from Jane about cost optimization review",
    "source_breadcrumb": "Outlook: Re: Cost optimization review",
    "relevance": 0.9,
    "pass_reason": "matches focus_area: cost optimization"
  }]
}
```

## Instructions
1. Auto-pass (relevance=1.0): flagged, saved, direct @mention, GitHub review_requested, GitHub assigned. pass_reason = "flagged"/"saved"/"direct mention"/"review requested"/"assigned". If the item is still flagged/saved/assigned at AM brief time, include it even if it originated yesterday or before the overnight lookback window.
2. Others: score 0-1 based on overlap with profile's focus_areas, key_contacts, active_threads.
3. Include if relevance ≥ 0.4. Write pass_reason explaining which profile element matched.
4. Below threshold: silently drop.
5. Max 10 signals. Sort by relevance descending.
