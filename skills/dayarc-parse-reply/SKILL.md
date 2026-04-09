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

The user may write in any free-form style — there are no required keywords or formats. Read each sentence for **intent** and extract meaning, even when phrasing is indirect or implicit.

1. Parse natural language corrections. Infer the action from context — do not require specific trigger words:
   - **mark_done**: any sentence conveying that something was completed, sent, fixed, resolved, or handled. Examples of intent (not exhaustive): "X is done", "finished X", "I already fixed the issue related to X", "I already sent the mail to my peer about X", "that's shipped", "merged", "resolved the X problem".
   - **remove**: any sentence conveying that something is no longer relevant, was cancelled, doesn't need tracking, or should be dropped. Examples: "drop X", "X got cancelled", "no longer relevant", "ignore X", "we decided not to do X".
   - **add_priority**: any sentence conveying a new thing to track, do, or remember. Examples: "remind me to X", "I need to X", "add X as priority", "don't forget X", "new priority: X", "I should chat with PM".
   - **correct**: any sentence conveying that existing information is wrong or needs updating. Examples: "actually X is ...", "correction: ...", "X should be Y not Z".
   - **For indirect references** (e.g. "I already fixed the issue related to the UI"): extract the most specific identifiable subject as `target` (e.g. "UI issue") and note the indirect phrasing in `detail`.
2. Parse quality signals — sentences that evaluate the brief itself (not specific work items). Classify sentiment and extract detail:
   - **positive**: any expression of approval, usefulness, or accuracy about the brief. Examples: "great brief", "spot on", "exactly right", "really useful", "perfect", "loved the summary".
   - **negative**: any expression that the brief was noisy, inaccurate, incomplete, or off-focus. Examples: "too much noise", "priorities were off", "missed my X work", "not relevant", "wrong focus", "too long", "cluttered".
   - Map each match to `{ sentiment: "positive"|"negative", detail: "<normalized phrase or quoted fragment>" }`.
3. Ignore purely social/phatic replies with no work content: "thanks", "looks good", "ok", "got it", "👍". These produce neither a correction nor a quality signal.
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

**Free-form implicit completion (indirect reference to a work item):**
```
Input: "I already fixed the issue that related to the UI"
Output: { "corrections": [{ "action": "mark_done", "target": "UI issue", "detail": "User says already fixed" }], "quality_signals": [] }
```

**Free-form implicit completion (action already taken):**
```
Input: "I already sent the mail to my peer"
Output: { "corrections": [{ "action": "mark_done", "target": "send mail to peer", "detail": "User says already sent" }], "quality_signals": [] }
```

**Free-form reminder / new priority:**
```
Input: "remind me to chat with PM"
Output: { "corrections": [{ "action": "add_priority", "target": "chat with PM", "detail": "User reminder" }], "quality_signals": [] }
```

**Mixed free-form reply:**
```
Input: "I already fixed the UI issue. Also remind me to chat with PM about the roadmap. The brief was a bit too long though."
Output: {
  "corrections": [
    { "action": "mark_done", "target": "UI issue", "detail": "User says already fixed" },
    { "action": "add_priority", "target": "chat with PM about roadmap", "detail": "User reminder" }
  ],
  "quality_signals": [{ "sentiment": "negative", "detail": "brief was too long" }]
}
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
