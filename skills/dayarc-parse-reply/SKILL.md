---
name: Parse Reply
description: Extract corrections from user's reply to a brief email.
---

## Input
Text of the user's reply to a brief email.

## Pre-processing

### 1. Strip HTML (if input is HTML)

If the input contains HTML tags, extract plain text before doing anything else:
- Remove all HTML tags (e.g. `<div>`, `<p>`, `<br>`, `<span>`, `<b>`, `<blockquote>`, etc.)
- Decode HTML entities (`&nbsp;` → space, `&amp;` → `&`, `&lt;` → `<`, `&gt;` → `>`, `&quot;` → `"`)
- Collapse multiple consecutive blank lines into a single blank line
- Strip leading/trailing whitespace from each line

### 2. Strip quoted original email

After HTML stripping (or if input was already plain text), remove everything below the first occurrence of any of these separator patterns:
- A line starting with `From:`
- A line starting with `Sent:`
- A line that is exactly `---` or `___` or `***`
- A line starting with `>` followed by `On ... wrote:`
- A line starting with `________________________________` (Outlook's horizontal rule in plain-text format)
- A line matching `On .{5,80} wrote:` (Outlook's "On Mon 24 Mar, Dayarc <...> wrote:" pattern)

Only parse the text **above** the first separator.

### 3. Strip email signatures

After removing quoted text, also discard lines from the first occurrence of a signature block marker:
- A line that is exactly `--` (standard signature delimiter)
- A line containing only `Sent from my iPhone` / `Sent from my Android` / `Get Outlook for iOS` (and similar auto-appended footers)

Only parse the text **above** the first signature marker.

## Output (JSON)
```json
{
  "corrections": [{
    "action": "mark_done",
    "target": "auth migration",
    "detail": "User says auth migration is complete"
  }],
  "quality_signals": [{
    "sentiment": "negative",
    "detail": "too much noise in inbox section"
  }]
}
```

## Instructions
1. Parse natural language corrections. Map to actions:
   - **mark_done**: "X is done", "finished X", "completed X", "X is complete"
   - **remove**: "drop X", "remove X", "X is no longer relevant", "ignore X"
   - **add_priority**: "add X as priority", "X should be tracked", "new priority: X"
   - **correct**: "X is wrong, it should be Y", "actually X is ...", "correction: ..."
2. Parse quality signals — replies that evaluate the brief itself (not specific items). Classify sentiment and extract detail:
   - **positive**: "great brief", "good brief", "this is helpful", "spot on", "exactly right", "loved the summary", "perfect"
   - **negative**: "too much noise", "priorities were off", "missed my X work", "not relevant", "wrong focus", "too long", "cluttered", "irrelevant", "missed X"
   - Map each match to `{ sentiment: "positive"|"negative", detail: "<normalized phrase or quoted fragment>" }`.
3. Ignore non-actionable replies: "thanks", "looks good", "ok", "got it", "👍". These produce neither a correction nor a quality signal.
4. A reply may contain both corrections and quality signals — extract all.
5. If no actionable content found, return empty arrays for both `corrections` and `quality_signals`.

## Examples

**Single correction:**
```
Input: "Auth migration is done, shipped yesterday"
Output: { "corrections": [{ "action": "mark_done", "target": "auth migration", "detail": "Shipped yesterday" }], "quality_signals": [] }
```

**Multiple corrections:**
```
Input: "Drop the perf review prep — it got cancelled. Also add quarterly OKR planning as a new priority."
Output: {
  "corrections": [
    { "action": "remove", "target": "perf review prep", "detail": "Cancelled" },
    { "action": "add_priority", "target": "quarterly OKR planning", "detail": "New priority from user" }
  ],
  "quality_signals": []
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

Output: { "corrections": [{ "action": "mark_done", "target": "cost optimization", "detail": "User confirmed done" }], "quality_signals": [] }
```

**Quality signal (positive):**
```
Input: "Great brief today, really useful"
Output: { "corrections": [], "quality_signals": [{ "sentiment": "positive", "detail": "great brief, really useful" }] }
```

**Quality signal (negative):**
```
Input: "Too much noise in the inbox section, priorities were off"
Output: { "corrections": [], "quality_signals": [{ "sentiment": "negative", "detail": "too much noise in inbox section" }, { "sentiment": "negative", "detail": "priorities were off" }] }
```

**Mixed correction and quality signal:**
```
Input: "Auth migration is done. Also the brief missed my PR review work."
Output: {
  "corrections": [{ "action": "mark_done", "target": "auth migration", "detail": "User confirmed done" }],
  "quality_signals": [{ "sentiment": "negative", "detail": "missed PR review work" }]
}
```

**No-op reply:**
```
Input: "Looks good, thanks!"
Output: { "corrections": [], "quality_signals": [] }
```

**Non-actionable single-word/emoji reply:**
```
Input: "ok"
Output: { "corrections": [], "quality_signals": [] }
```

```
Input: "👍"
Output: { "corrections": [], "quality_signals": [] }
```

**HTML-wrapped reply with signature (Outlook format):**
```
Input:
"<html><body><div style='font-family:Calibri'>
<p>Auth migration is done.</p>
<p>Also drop the perf review prep item.</p>
<div>-- <br>Jane Smith<br>Engineering Manager</div>
<blockquote style='border-left:1px solid #ccc'>
<div>From: Dayarc &lt;jane@company.com&gt;</div>
<div>Sent: Tuesday, April 9, 2026 8:00 PM</div>
<div>Subject: 🌙 Evening Wrap-up — Tue 9 Apr</div>
<div>... original brief ...</div>
</blockquote>
</div></body></html>"

Output: {
  "corrections": [
    { "action": "mark_done", "target": "auth migration", "detail": "User confirmed done" },
    { "action": "remove", "target": "perf review prep", "detail": "User requested removal" }
  ],
  "quality_signals": []
}
```

**HTML reply with Outlook horizontal rule separator:**
```
Input:
"<html><body><div>
<p>Cost optimization review is complete.</p>
<p>________________________________</p>
<p>From: Dayarc &lt;jane@company.com&gt;<br>
Sent: Wednesday, April 9, 2026<br>
Subject: ☀️ Morning Brief — Wed 9 Apr</p>
</div></body></html>"

Output: { "corrections": [{ "action": "mark_done", "target": "cost optimization review", "detail": "User confirmed complete" }], "quality_signals": [] }
```

**All five correction types in one reply:**
```
Input: "Auth migration is done. Drop the perf review — it got cancelled. Add quarterly OKR planning as priority. Actually the ARM CI issue is a flaky test, not a build failure."
Output: {
  "corrections": [
    { "action": "mark_done", "target": "auth migration", "detail": "User confirmed done" },
    { "action": "remove", "target": "perf review", "detail": "Cancelled" },
    { "action": "add_priority", "target": "quarterly OKR planning", "detail": "New priority from user" },
    { "action": "correct", "target": "ARM CI issue", "detail": "Flaky test, not a build failure" }
  ],
  "quality_signals": []
}
```

---

## Dry-Run Validation

When running in conversational (non-scheduled) mode, after returning the parsed JSON, echo a human-readable summary to the terminal:

```
📬 Reply parsed:
  Corrections (3):
    ✅ mark_done  → auth migration
    ❌ remove     → perf review prep
    ➕ add_priority → quarterly OKR planning
  Quality signals (1):
    👎 negative: "priorities were off"
  Profile fields that will be updated:
    active_threads: auth migration → status: "done"
    priorities_today: perf review prep removed
    priorities_today: quarterly OKR planning added (urgency: 🟡 soon)
    feedback: { sentiment: "negative", detail: "priorities were off" }
```

If `corrections` is empty and `quality_signals` is empty, output:
```
📬 Reply parsed: no actionable content — skipping profile update.
```

This dry-run echo happens before any memory write, so the user can verify corrections are correct before they're applied.
