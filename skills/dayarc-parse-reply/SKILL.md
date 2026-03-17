---
name: Parse Reply
description: Extract corrections from user's reply to a brief email.
---

## Input
Text of the user's reply to a brief email.

## Output (JSON)
```json
{
  "corrections": [{
    "action": "mark_done",
    "target": "auth migration",
    "detail": "User says auth migration is complete"
  }]
}
```

## Instructions
1. Parse natural language corrections: "X is done", "drop X", "add Y as priority", "X is wrong".
2. Map to actions: mark_done, remove, add_priority, correct.
3. Ignore non-actionable replies: "thanks", "looks good", "ok".
4. If no actionable content found, return empty corrections array.
