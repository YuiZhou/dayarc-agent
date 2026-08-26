---
name: Review Prep
description: Generate structured talking points for performance reviews, 1:1s, and self-assessments from accumulated monthly summaries.
---

## When to Use

Trigger this skill when the user says anything like:
- "Generate self-review talking points for Q1"
- "Prep my 1:1 with my manager"
- "Generate review talking points"
- "What should I say in my performance review?"
- "Prepare self-assessment for {period}"
- "1:1 prep" / "review prep"
- Any request combining "review", "self-assessment", "1:1", or "talking points" with a time period or the user's work history

## Overview

This skill reads 1–6 monthly summaries and synthesizes structured talking points for a performance review, 1:1, or self-assessment. Output is rendered to the terminal only — no email, no memory write.

---

## Input

Monthly summaries from memory:
- `monthly-archive/{YYYY-MM}.json` — archived monthly summaries (up to 6)
- `monthly-summary.json` — the most recent monthly summary

The skill determines how many months to include based on the user's request:
- If the user names a quarter (e.g., "Q1"), include the 3 months of that quarter.
- If the user names a specific range (e.g., "last 3 months"), include that many.
- If no period is specified, default to the last 3 months.
- Cap at 6 months regardless of what is requested.

## Instructions

### Step 1 — Read Monthly Summaries

Via **dayarc-memory**, read:
1. `monthly-summary.json` (most recent month)
2. All files in `monthly-archive/` directory

Sort by month descending (most recent first). Select the months that fall within the requested period. If fewer months are available than requested, proceed with what exists and note the gap in the output.

If no monthly summaries exist at all, output:

> ⚠️ No monthly summaries found. Run a monthly brief first (or wait until the end of the month) to build the data this skill needs.

Then stop.

### Step 2 — Synthesize Talking Points

Analyze the selected monthly summaries and produce the following sections. Deduplicate items that appear in multiple months. Where applicable, note month-over-month changes.

#### A. Key Accomplishments
- Prefer structured `impact_summaries` across all selected months. Fall back to `accomplishments` for older memory
  files that do not contain impact summaries.
- Deduplicate: if the same item appears in multiple months, keep it once (in the month it was first completed).
- Group by theme (e.g., "Infrastructure", "Team/Process", "Product/Feature").
- Maximum 10 items total.
- Format each item as an outcome-led statement using its action, result, and impact. Include source context where
  available.

#### B. Impact Areas
- Pull from `time_allocation` across all selected months.
- For each area, show:
  - Average effort share across the period
  - Trend direction (↑ increased, → steady, ↓ decreased, ★ new, ✕ dropped)
- List top 5 areas by average effort share.
- One-line impact narrative per area: what moved because of this work.

#### C. Growth & Learning
- Pull from `learning_progress` across all selected months.
- Deduplicate topics; for each, show overall trajectory across the period.
- Highlight topics with "rising" trajectory as growth areas.
- Flag topics with "declining" trajectory and include recommendation.
- Maximum 5 topics.

#### D. Challenges & Blockers
- Pull from `persistently_stuck` across all selected months.
- For each: note how many weeks it was stuck and whether it was eventually resolved (absent from later months = likely resolved).
- Flag items still stuck in the most recent month.
- Maximum 5 items.

#### E. Focus Shifts
- Compare `time_allocation` month-over-month.
- Identify: areas that grew significantly (>10% share increase), areas that shrank or dropped, new areas that appeared, and any pivots the user made.
- Present as a brief narrative (3–5 sentences) summarizing how priorities evolved across the period.

#### F. Talking Points
- Write 5–7 crisp one-liners suitable for a review document or verbal summary.
- Each should be a complete, impactful sentence that stands alone.
- Draw from accomplishments, impact, and growth — not from blockers.
- Reuse the evidence and wording from monthly `impact_summaries`; do not infer unsupported metrics or outcomes.
- Format: numbered list.
- Example: `1. Drove the authentication migration from design to production, reducing login latency by X%.`

### Step 3 — Render Output

Render to the terminal in the following format. Keep total output under ~2 pages (≈800 words).

```
╔══════════════════════════════════════════════════════╗
║   Review Prep — {period label}                       ║
╚══════════════════════════════════════════════════════╝

Data: {N} month(s) — {start month} to {end month}
{If any months were missing: ⚠️ Note: {missing months} not available.}

───────────────────────────────────────────────────────
🏆  KEY ACCOMPLISHMENTS
───────────────────────────────────────────────────────

{Theme group}
  • {accomplishment}
  • {accomplishment}

{Theme group}
  • {accomplishment}

───────────────────────────────────────────────────────
📊  IMPACT AREAS
───────────────────────────────────────────────────────

  {area} — {avg effort share}% avg  {trend arrow}
    {one-line impact narrative}

───────────────────────────────────────────────────────
📈  GROWTH & LEARNING
───────────────────────────────────────────────────────

  {topic} — {trajectory}
    {recommendation}

───────────────────────────────────────────────────────
🧱  CHALLENGES & BLOCKERS
───────────────────────────────────────────────────────

  • {blocker} — stuck {N} weeks  {🔴 still open | ✅ resolved}

───────────────────────────────────────────────────────
🔄  FOCUS SHIFTS
───────────────────────────────────────────────────────

  {3–5 sentence narrative of how priorities evolved}

───────────────────────────────────────────────────────
💬  TALKING POINTS  (copy-paste ready)
───────────────────────────────────────────────────────

  1. {crisp one-liner}
  2. {crisp one-liner}
  ...

───────────────────────────────────────────────────────
```

## Edge Cases

- **Sparse data (1 month only):** Skip the "Focus Shifts" section — there is no month-over-month to compare. Note: "Focus Shifts requires 2+ months of data."
- **Missing months in a quarter:** Proceed with available months and add a ⚠️ note at the top listing which months were missing.
- **No accomplishments:** Omit the Key Accomplishments section header and note: "No accomplishments recorded in this period."
- **No stuck items:** Omit the Challenges & Blockers section and note: "No persistent blockers recorded in this period."
- **No learning data:** Omit the Growth & Learning section and note: "No learning progress recorded in this period."
- **Locale:** If `config.json` has a non-`en` locale, translate the rendered output into that language before displaying. Preserve formatting markers (box-drawing characters, emoji, numbers) unchanged.
