---
name: Explain Why
description: Answer 'why is X in my priorities/activities/signals/drift alerts?' by tracing a brief item back to its source signals and breadcrumbs.
---

## When to Use

Invoke this skill when the user asks a question matching any of these patterns (case-insensitive):
- "why is [item] in my priorities?"
- "why did [item] show up?"
- "where does [item] come from?"
- "what signals produced [item]?"
- "why am I seeing [item]?"
- Any question containing "why" paired with a named item from a brief (priority, activity, drift alert, or signal).

## Output

Render to terminal only. Do NOT send email or write to memory.

```
📍 Why "[item name]"?

Source breadcrumb: [source_breadcrumb]
Urgency / relevance: [urgency or relevance score]
Pass reason: [pass_reason, if applicable]

This item was produced by: [skill name]
Found in: [memory file and field path]
```

If multiple breadcrumbs exist (e.g., item appears in both priorities and activities), show all of them.

## Instructions

### Step 1 — Parse the item name

Extract the subject noun phrase from the user's question. For example:
- "Why is auth migration in my priorities?" → `auth migration`
- "Why did the cost review show up?" → `cost review`
- "Where does ARM CI pipeline come from?" → `ARM CI pipeline`

### Step 2 — Search memory (most-recent first)

Search the following memory files in order, stopping as soon as the item is found. Use the **dayarc-memory** skill to read each file. Match by fuzzy keyword overlap (not exact string match).

1. **`daily/daily-profile-{today}.json`** — check these fields:
   - `priorities_today[].description` + `priorities_today[].source_breadcrumb` (produced by `infer_priorities`)
   - `unfinished[].description` + `unfinished[].source_breadcrumb` (produced by `learn_user_profile`)
   - `active_threads[].subject` + `active_threads[].source_breadcrumb`
   - `impact_summaries[]` across `title`, `situation`, `task`, `action`, `result`, and `impact`, plus
     `source_breadcrumbs[]` (produced by `write_impact_summary`)

2. **`weekly-summary-current.json`** — check:
   - `themes[].label` + any breadcrumbs stored under activities for that theme
   - `stuck[].description` + `stuck[].source_breadcrumb`
   - `impact_summaries[]` + `source_breadcrumbs[]`

3. **`monthly-summary.json`** — check:
   - `themes[].label` + activity breadcrumbs
   - `stuck[].description` + `stuck[].source_breadcrumb`
   - `impact_summaries[]` + `source_breadcrumbs[]`

4. **Recent daily profiles** — if today's profile has no match, try the previous 3 days:
   `daily/daily-profile-{yesterday}.json`, `{day-2}.json`, `{day-3}.json`.
   In each, check `priorities_today`, `unfinished`, `active_threads`, and `impact_summaries` as above.

### Step 3 — If item not found in memory

If no match is found across all memory files, say:

> I couldn't find "[item]" in your recent memory (last 3 days, current weekly, current monthly). It may be from an older brief or may have been removed. Try asking about a specific date, e.g. "why was auth migration in my priorities on March 20?"

### Step 4 — Render breadcrumbs

Once the item is found, render all available source fields:

- **For priorities** (`infer_priorities` output): show `source_breadcrumb` and `urgency`.
- **For activities** (`classify_activity` output): show `source_breadcrumb` per activity in the theme cluster.
- **For impact summaries** (`write_impact_summary` output): show all `source_breadcrumbs` and identify the matching
  situation, task, action, result, or impact field.
- **For drift alerts** (`detect_drift` output): show `source_breadcrumb` (the priority that was neglected) and `days_inactive`.
- **For signals** (`filter_signals` output): show `source_breadcrumb`, `relevance`, and `pass_reason`.

Apply the breadcrumb quality rule: if a breadcrumb contains a Teams meeting thread link (`19:meeting_...@thread.v2`), flag it with ⚠️ and include whatever fallback context (meeting title, date, participants) is stored alongside it.

### Step 5 — Cite the source skill

End the response with a one-line attribution:
> *Produced by `[skill-name]` · found in `[memory-file]` › `[field-path]`*

Example:
> *Produced by `infer_priorities` · found in `daily-profile-2026-03-28.json` › `priorities_today[1]`*
