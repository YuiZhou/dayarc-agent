# Dayarc — Product Specification

**Status:** Draft | **Updated:** 2026-03-16

---

## 1. Problem

Too much noise across Outlook, Teams, GitHub, and SharePoint. No single view of what matters. Day-to-day I lose track of what I did; week-to-week I lose sight of where my time went. I need automated briefs to plan and wrap up, periodic rollups for patterns and drift, and a way to query and correct the system interactively.

---

## 2. Use Cases

| Pri | Use Case | Description |
|-----|----------|-------------|
| **P0** | **Conversational query** | Ask the agent natural-language questions about my work — priorities, todos, status, contacts, drift. Agent uses memory + live signals to answer. |
| **P0** | **Scheduled briefs** | Automated daily (AM/PM), weekly, and monthly email briefs — no manual trigger. Scheduling is optional; briefs can also be triggered conversationally ("send me a morning brief"). |

**Scheduled vs. conversational runs:**
- **Scheduled runs** send email, write memory, write run tags. They are the authoritative source of truth.
- **Conversational triggers** ("send me a morning brief") render to terminal by default, do not write memory or run tags. The user can explicitly ask to send email or persist.
- Signal window is always "since last brief of that type" regardless of trigger mode.
| **P1** | **Memory correction** | Correct the agent's understanding via conversation ("mark auth migration as done", "add 'prepare demo' as priority") or by replying to a brief email. Updates persist to memory. |
| **P1** | **Portable workspace** | User data (memory + config) is self-contained. Copy to another machine, install agent, authenticate → works. |

---

## 3. Goals & Non-Goals

**Goals:**
- **G1.** PM brief (8 PM, Mon–Fri): what I did, priorities, unfinished. Side-effect: learn focus/interests.
- **G2.** AM brief (8 AM, Mon–Fri): today's plan, learning recs, filtered signals, drift alerts.
- **G3.** Weekly report (Friday PM): themes, accomplishments, stuck items, next-week focus.
- **G4.** Monthly report (last workday): time allocation, trends, learning progress, next-month outlook.
- **G5.** Daily ≤ ~1 page. Weekly/Monthly ≤ ~2 pages. All scannable in < 5 min.
- **G6.** Personal only, runs under my own identity.

**Non-Goals:** No autonomous write actions on external systems. No team reporting. No exhaustive coverage. No attachments. No weekend runs.

---

## 4. Scenarios

1. **Evening wrap-up** — PM brief: grouped activities, priorities, unfinished items.
2. **Morning planning** — AM brief: action items, learning topics, filtered signals, drift alerts.
3. **Focus shift** — PM detects new themes in outgoing signals; AM adapts filtering next morning.
4. **Monday catch-up** — AM lookback extends to cover Sat + Sun.
5. **Weekly reflection** — Friday: 60% on auth migration, one PR stuck 3 days, eBPF interest growing.
6. **Monthly arc** — Auth migration dominated March, cost optimization emerged mid-month, two old areas dropped.
7. **Conversational query** — "What are my priorities this week?" → agent reads memory + signals, answers in natural language.
8. **Memory correction (conversation)** — "Mark auth migration as done" → agent updates daily profile, confirms.
9. **Memory correction (email reply)** — Reply to PM brief: "auth migration is done, drop it" → next brief reflects the change.
10. **Dry run** — "Show me what the morning brief would look like" → agent renders brief in terminal, doesn't send email.
11. **Machine migration** — Copy user data folder to new laptop → install agent → authenticate → same memory, same briefs.

---

## 5. Data Sources

All read-only, under my own M365 / GitHub identity. No full message bodies stored or forwarded.

| Source | Used by |
|--------|---------|
| Outlook — Sent Mail, Flagged Emails, Inbox, Calendar | PM learn, PM/AM priorities, AM filter/plan |
| Teams — My Messages, Saved Messages, Incoming | PM learn, PM/AM priorities, AM filter |
| GitHub — My Activity (PRs, issues, commits), Notifications | PM learn, AM filter |
| SharePoint / OneDrive — Recent documents | PM learn |
| Outlook — Brief Replies | Memory correction (email reply) |

---

## 6. PM Brief (8 PM, Mon–Fri)

**Actionability rule (applies to all briefs):** Every item must describe *what* it is and include a source breadcrumb (link, thread subject, or channel). No opaque reminders.

### A. "What I Did Today"
Activities grouped by theme. One sentence per bullet. **Max 15.**

### B. "My Priorities Today"
Rank order: **Outlook flags / Teams saves** → high-effort activities → meetings attended. **Max 5.**

### C. "Left Unfinished"
PR reviews not submitted, questions unanswered, calendar follow-ups without activity, open assigned issues. **Max 5.**

### D. Focus & Interest Update *(hidden — not in email)*
Extracts focus areas and learning interests from outgoing signals. Persisted to daily profile.

---

## 7. AM Brief (8 AM, Mon–Fri)

Mondays: lookback extends to cover Sat + Sun.

### A. "Today's Plan"
Prioritized action items (in rank order):
1. **Flagged / Saved** — always included
2. **Direct @mentions** (Outlook To-line, Teams @, GitHub @) — always included
3. **Carryover** from last PM brief
4. **Calendar** — today's meetings, prep needed
5. **Inbound requests** — filtered for relevance
6. **GitHub** — PRs awaiting review, assigned issues

**Max 8.** Each: one-line description, source breadcrumb, urgency (`🔴 urgent` · `🟡 soon` · `🔵 when-free`).

### B. "Recommended Learning"
**3–5 topics** from profile. Each: label, connection to my work, 1–2 links. Rotates daily.

### C. "Incoming Signals"
Relevance-filtered emails/Teams/GitHub. Flags, saves, and @mentions **always pass**. Below threshold → silently dropped. **Max 10.**

### D. "You May Forget"
Reads weekly + monthly summaries every morning. Surfaces priorities with **no matching activity** for 2+ days (weekly) or the current week (monthly). **Max 3.** Omitted entirely if all on track.

---

## 8. Weekly Report (Friday 8 PM)

Summarized from the week's daily reports — not from raw data.

- **A. "This Week's Themes"** — Top 3–5 workstreams by effort, one-line progress each.
- **B. "Accomplishments"** — PRs merged, threads resolved, milestones hit. **Max 8.**
- **C. "Stuck / Recurring Carryovers"** — Items unfinished on **2+ days**. **Max 5.**
- **D. "Next Week's Suggested Focus"** — 3–5 priorities from momentum, carryovers, calendar.
- **E. Weekly Memory Update** *(hidden)* — Snapshots into weekly memory layer.

---

## 9. Monthly Report (Last Workday)

Summarized from the month's weekly reports — not from raw data or dailies.

- **A. "Where My Time Went"** — Focus area breakdown: effort share, what grew/shrank/appeared/dropped.
- **B. "Key Accomplishments"** — Deduplicated roll-up from weeklies. **Max 10.**
- **C. "Persistently Stuck"** — Items stuck **2+ weeks**.
- **D. "Learning Progress"** — Trajectory (growing / plateaued / dropped), go deeper or let go.
- **E. "Next Month's Outlook"** — 3–5 strategic priorities from trends + calendar.
- **F. Monthly Memory Update** *(hidden)* — Snapshots into monthly memory layer.

---

## 10. Layered Memory

Communication between briefs only through shared memory files — never by calling each other. **Chain of distillations, not an archive.**

| Layer | Written by | Retain | Feeds |
|-------|-----------|--------|-------|
| Daily profile | PM brief | Up to 5 (current week; purged on weekly rotation) | Every AM brief, weekly report |
| Weekly summary | Weekly report | 2 (current + prev) | Every AM brief |
| Monthly summary | Monthly report | 1 (latest) | Every AM brief |

- **Daily** profiles accumulate Mon–Fri (up to 5). Weekly report reads all 5, then purges them.
- **Weekly** absorbs previous weekly's unresolved items before discarding it.
- **Monthly** absorbs previous monthly's trends before discarding it.
- AM reads **all three layers every morning** for planning, filtering, and drift detection.
- **Memory corrections** (see §11) update the daily profile only; changes propagate to weekly/monthly through the distillation chain.

All layers: human-readable JSON, manually overridable.
**Bootstrap:** empty → AM shows all signals unfiltered; first PM/Friday/month-end builds each layer.

---

## 11. Memory Correction

Two ways to correct the agent's understanding:

**A. Conversation (P1):** Tell the agent directly — "mark X as done", "add Y as priority", "drop Z from focus." Agent updates the daily profile and confirms. Works in any interactive session.

**B. Email reply (P1):** Reply to any brief email with corrections. Agent searches inbox for replies matching brief subject patterns (`RE: ☀️ Morning Brief`, etc.) at the start of each scheduled run, parses explicit corrections, and updates the daily profile before proceeding.

**Rules:**
- Both methods update the **daily profile** only. Changes propagate to weekly/monthly through the distillation chain.
- Non-actionable input ("thanks", "looks good") → ignored.
- Reply content not stored beyond the memory update.

---

## 12. Portable Workspace

Three layers with different portability:

| Layer | Contains | Portable? |
|-------|----------|-----------|
| **Agent code** | Agent profile, skills, templates | Installed with agent package. Identical across machines. |
| **User data** (`~/Documents/dayarc/`) | `memory/` (all JSON), `config.json` (identity, preferences) | **Yes — copy to any machine.** |
| **Scheduler** | Trigger scripts, OS task registration | Machine-specific. Optional — only needed for automated runs. |

**Portability:** Copy user data folder → install agent → authenticate (`gh auth login`, M365 sign-in) → run. Full memory carries over.

**Cross-platform:** Agent code and user data are pure Markdown + JSON — platform-independent. Only the scheduler and email delivery (Outlook COM) are Windows-specific; these can be adapted per platform.

---

## 13. Delivery

| Property | Value |
|----------|-------|
| Channel | Email to self |
| Format | HTML with sections and bullets |
| Daily | 8 AM + 8 PM, Mon–Fri |
| Weekly | Friday 8 PM |
| Monthly | Last workday, 8 PM |
| Subjects | `☀️ Morning Brief — {date}` · `🌙 Evening Wrap-up — {date}` · `📊 Weekly — Week of {date}` · `📅 Monthly — {month} {year}` |
| Max length | Daily ≤ ~750w · Weekly/Monthly ≤ ~1,500w |
| Sender | Self · No attachments |
| Dry run | "Show me what the brief would look like" → renders in terminal. Pure preview: no email sent, no memory writes, no run tag. Scheduled runs remain authoritative. |

---

## 14. Safety

| Rule | Level |
|------|-------|
| **Read-only externally.** Only writes = email to self + local memory files. | Hard |
| **No data exfiltration.** All processing within Microsoft boundary (M365 + GitHub Copilot API). No data sent to third parties. | Hard |
| **No impersonation.** Summarizes only — never drafts replies. | Hard |
| **Graceful degradation.** Missing source → send with available data, note gap. | Soft |
| **Idempotent.** Duplicate run → no side effects. | Soft |

---

## 15. Success Criteria

| Metric | Target |
|--------|--------|
| Read time | < 5 min per brief |
| Relevance precision | ≥ 80% of AM signals feel relevant (after 2 weeks) |
| Coverage | No consistently missed items in PM "What I Did" (after 1 week) |
| Focus accuracy | Learned focus ≈ self-reported (after 1 week) |
| Write violations | Zero |
