---
name: Parse Reply
description: Extract corrections from user's reply to a brief email.
---

## Input
Text of the user's reply to a brief email.

## Pre-processing

Before parsing, strip everything below the first occurrence of any of these separator patterns (original email quote):
- A line starting with `From:`
- A line starting with `Sent:`
- A line that is exactly `---` or `___` or `***`
- A line starting with `>` followed by `On ... wrote:`

Only parse the text **above** the first separator.

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
1. Parse natural language corrections. Map to actions:
   - **mark_done**: "X is done", "finished X", "completed X", "X is complete"
   - **remove**: "drop X", "remove X", "X is no longer relevant", "ignore X"
   - **add_priority**: "add X as priority", "X should be tracked", "new priority: X"
   - **correct**: "X is wrong, it should be Y", "actually X is ...", "correction: ..."
2. Ignore non-actionable replies: "thanks", "looks good", "ok", "got it", "👍".
3. If no actionable content found, return empty corrections array.

## Examples

**Single correction:**
```
Input: "Auth migration is done, shipped yesterday"
Output: { "corrections": [{ "action": "mark_done", "target": "auth migration", "detail": "Shipped yesterday" }] }
```

**Multiple corrections:**
```
Input: "Drop the perf review prep — it got cancelled. Also add quarterly OKR planning as a new priority."
Output: {
  "corrections": [
    { "action": "remove", "target": "perf review prep", "detail": "Cancelled" },
    { "action": "add_priority", "target": "quarterly OKR planning", "detail": "New priority from user" }
  ]
}
```

**Quoted reply (strip original):**
```
Input:
"Cost optimization is done

From: Dayarc <myself@company.com>
Sent: Monday, March 24, 2026 8:00 PM
Subject: 🌙 PM Brief — Mon 24 Mar

Section A: What you accomplished today
..."

Output: { "corrections": [{ "action": "mark_done", "target": "cost optimization", "detail": "User confirmed done" }] }
```

**No-op reply:**
```
Input: "Looks good, thanks!"
Output: { "corrections": [] }
```
