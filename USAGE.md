# Dayarc — Usage Guide

## Prerequisites

| Requirement | How to verify |
|-------------|--------------|
| **Copilot CLI** ≥ 1.0.5 | `copilot --version` |
| **GitHub CLI** authenticated | `gh auth status` — must show "Logged in" |
| **M365 session** signed in | Open Outlook desktop at least once |
| **Outlook desktop** running | Required only when sending email briefs |

---

## Installation

The agent is three pieces: an **agent package** (installed per machine), **user data** (synced via OneDrive), and an optional **scheduler**.

### 1. Agent package → `~/.dayarc-agent/`

Clone the repo and copy the agent package:

```powershell
git clone https://github.com/YuiZhou/dayarc-agent
cd dayarc

# Copy agent package
$dest = Join-Path $HOME ".dayarc-agent"
Copy-Item -Recurse agents, skills, prompts, memory-schemas.md, mcp.json, scheduler.ps1 $dest
```

This creates:

```
~/.dayarc-agent/
├── agents/dayarc.agent.md              # agent profile
├── skills/
│   ├── dayarc-classify-activity/SKILL.md
│   ├── dayarc-infer-priorities/SKILL.md
│   ├── dayarc-learn-user-profile/SKILL.md
│   ├── dayarc-filter-signals/SKILL.md
│   ├── dayarc-detect-drift/SKILL.md
│   ├── dayarc-summarize-period/SKILL.md
│   ├── dayarc-parse-reply/SKILL.md
│   ├── dayarc-memory/SKILL.md
│   └── dayarc-deliver/
│       ├── SKILL.md
│       └── templates/{pm,am,weekly,monthly}.hbs
├── prompts/
│   ├── pm.md                             # Evening Wrap-up plan
│   ├── am.md                             # Morning Brief plan
│   ├── weekly.md                         # Weekly Report plan
│   └── monthly.md                        # Monthly Report plan
├── memory-schemas.md                     # Memory file schema reference
├── mcp.json                              # Work IQ + GitHub MCP servers
└── scheduler.ps1                         # Task Scheduler script (optional)
```

All plain Markdown + JSON — no compilation, no dependencies.

### 2. User data → `~/Documents/dayarc/`

> **Note:** On corp machines with OneDrive, `~/Documents/` typically maps to `C:\Users\you\OneDrive - Microsoft\Documents\`. This folder auto-syncs across your corp machines.

```powershell
mkdir ~/Documents/dayarc
cp config.example.json ~/Documents/dayarc/config.json
# Edit config.json with your details
```

```
~/Documents/dayarc/
├── config.json          # your identity + preferences
└── memory/              # JSON memory files (grows over time)
```

Edit `config.json`:

```json
{
  "user": {
    "display_name": "Your Name",
    "email": "you@company.com",
    "github_username": "your-gh-handle"
  },
  "preferences": {
    "brief_max_items": 15,
    "priority_max_items": 5,
    "unfinished_max_items": 5,
    "signal_max_items": 10,
    "plan_max_items": 8,
    "learning_items": 5,
    "drift_max_items": 3
  }
}
```

The `memory/` folder is created automatically on first brief run.

### 3. (Optional) Scheduler

Register Task Scheduler entries for automated daily briefs:

```powershell
$script = Join-Path $HOME ".dayarc-agent\scheduler.ps1"

# 8:00 AM — Morning Brief (Mon–Fri)
schtasks /create /tn "Dayarc-AM" /tr "powershell -File $script -trigger am" /sc weekly /d MON,TUE,WED,THU,FRI /st 08:00

# 8:00 PM — Evening Wrap-up (Mon–Fri, + Weekly on Fri, + Monthly on last workday)
schtasks /create /tn "Dayarc-PM" /tr "powershell -File $script -trigger pm" /sc weekly /d MON,TUE,WED,THU,FRI /st 20:00
```

The scheduler is optional — you can trigger any brief conversationally instead.

### 4. Migrate to a new machine

```powershell
# User data syncs automatically via OneDrive — nothing to copy.
# Just install the agent package on the new machine:

git clone https://github.com/YuiZhou/dayarc-agent
cd dayarc
$dest = Join-Path $HOME ".dayarc-agent"
Copy-Item -Recurse agents, skills, prompts, memory-schemas.md, mcp.json, scheduler.ps1 $dest

# Authenticate
gh auth login
# Open Outlook and sign in to M365
# (Optional) Re-register scheduler — see step 3
```

Memory, config, and preferences are already on the new machine via OneDrive.

---

## How to Use

### Conversational mode (default)

Start a Copilot CLI session with Dayarc:

```bash
copilot --agent=dayarc
```

Then ask anything in natural language. The agent reads your memory and queries live data to answer.

**No emails sent, no memory written** — conversational mode is read-only by default.

---

## Scenarios

### 🔍 Ask about priorities

```
copilot --agent=dayarc

> What are my priorities today?
> What should I focus on this morning?
> Am I forgetting anything important?
```

The agent reads your latest daily profile + weekly/monthly summaries, checks GitHub and M365 for new signals, and gives you a prioritized answer with urgency tags (🔴🟡🔵).

---

### 📋 Preview a brief (dry run)

```
> Show me what the evening brief would look like
> Give me a dry run of the morning brief
```

Renders the full brief in your terminal — same content as the email, but nothing is sent or saved. Use this to check what the brief would contain before committing.

---

### 📧 Send a brief manually

```
> Send me the PM brief for today
> Run the morning brief and send it
```

When you explicitly say **"send"**, the agent:
1. Collects data from M365 + GitHub
2. Synthesizes the brief
3. Renders HTML from the template
4. Sends via Outlook COM to your own inbox
5. Writes the daily profile to memory
6. Writes a run tag for idempotency

---

### ❓ Query your work history

```
> What did I work on yesterday?
> Who have I been collaborating with this week?
> How much time did I spend on the CLI migration?
> What PRs are still open from last week?
```

The agent combines memory (daily profiles, weekly/monthly summaries) with live queries to M365 and GitHub.

---

### ✏️ Correct the agent's memory

The agent learns from your PM briefs. If it gets something wrong, correct it:

```
> Mark the auth migration as done
> Drop "prepare demo" from my priorities
> Add "finalize Q2 roadmap" as a 🔴 priority
> I didn't actually work on the dashboard today, remove it
```

Corrections update your **daily profile only**. Changes propagate to weekly and monthly summaries through the normal distillation chain.

You can also correct by **replying to a brief email** — the next brief run will parse your reply and apply corrections automatically.

---

### 📅 Monday morning catch-up

```
> What happened over the weekend?
> Give me the Monday morning brief
```

Monday AM briefs automatically extend the lookback window to cover Saturday and Sunday, so you don't miss anything.

---

### 🔄 Weekly and monthly reports

```
> Show me the weekly report
> What were my themes this week?
> Give me a monthly summary
```

Weekly and monthly reports are **pure distillation** — they don't query raw data. They synthesize from your accumulated daily/weekly profiles.

On Fridays, the scheduled run automatically chains: **PM → Weekly → Monthly** (if last workday of month).

---

### 🚨 Drift detection

```
> Am I forgetting anything?
> What priorities have I been neglecting?
> Are there any stuck items I should know about?
```

The agent compares your weekly/monthly priorities against your last 2 days of activity. Anything with **no matching activity for 2+ days** gets surfaced as a drift alert.

---

### 📊 Learning recommendations

```
> What should I learn about today?
> Any learning topics related to my current work?
```

The agent tracks your learning interests from outgoing signals (emails, PRs, Teams messages). It recommends **3–5 topics** daily, rotated, with connections to your active work.

---

## Scheduled mode (automated)

For fully automated daily briefs, register the scheduler (see [Installation §3](#3-optional-scheduler)):

```powershell
$script = Join-Path $HOME ".dayarc-agent\scheduler.ps1"

# Register (Mon–Fri)
schtasks /create /tn "Dayarc-AM" /tr "powershell -File $script -trigger am" /sc weekly /d MON,TUE,WED,THU,FRI /st 08:00
schtasks /create /tn "Dayarc-PM" /tr "powershell -File $script -trigger pm" /sc weekly /d MON,TUE,WED,THU,FRI /st 20:00

# Unregister
schtasks /delete /tn "Dayarc-AM" /f
schtasks /delete /tn "Dayarc-PM" /f
```

Scheduled runs are **authoritative**: they send email, write memory, and write run tags. If a scheduled run already completed for a given date+type, it won't re-send (idempotent).

### Scheduler vs. Conversational

| | Scheduled | Conversational |
|---|---|---|
| **Trigger** | OS Task Scheduler / cron | You type a prompt |
| **Email** | ✅ Always sent | ❌ Terminal only (unless you say "send") |
| **Memory** | ✅ Always written | ❌ Not written (unless you say "save") |
| **Run tag** | ✅ Idempotent | ❌ Never |
| **When** | 8 AM / 8 PM, Mon–Fri | Anytime |

---

## Brief types at a glance

| Brief | When | Sections | Max length |
|-------|------|----------|------------|
| **PM** (Evening Wrap-up) | 8 PM Mon–Fri | What I Did (≤15), Priorities (≤5), Unfinished (≤5) | ~1 page / 750 words |
| **AM** (Morning Brief) | 8 AM Mon–Fri | Today's Plan (≤8), Learning (3–5), Signals (≤10), You May Forget (≤3) | ~1 page / 750 words |
| **Weekly** | Friday 8 PM | Themes (3–5), Accomplishments (≤8), Stuck (≤5), Next Week (3–5) | ~2 pages |
| **Monthly** | Last workday | Time Allocation, Accomplishments (≤10), Stuck, Learning, Next Month (3–5) | ~2 pages |

---

## Memory layout

```
~/Documents/dayarc/memory/
├── daily/
│   ├── daily-profile-2026-03-10.json
│   ├── daily-profile-2026-03-11.json
│   ├── daily-profile-2026-03-12.json
│   ├── daily-profile-2026-03-13.json
│   └── daily-profile-2026-03-14.json   ← up to 5 (Mon–Fri)
├── weekly-summary-current.json
├── weekly-summary-prev.json
├── weekly-archive/                      ← current month only
├── monthly-summary.json
└── runs/
    ├── 2026-03-14-pm.json               ← idempotency tags
    └── 2026-03-14-am.json
```

All files are **human-readable JSON**. You can edit them manually if needed — the agent respects manual changes.

### Memory lifecycle

- **Daily profiles** accumulate Mon–Fri (up to 5). Weekly report reads all 5, then purges them.
- **Weekly summary** absorbs previous week's unresolved items, then archives prev.
- **Monthly summary** absorbs previous month's trends, then overwrites.
- **First run (bootstrap):** Empty memory is fine. AM shows all signals unfiltered; first PM builds the daily layer; first Friday builds weekly; first month-end builds monthly.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "gh CLI not authenticated" | Run `gh auth login` |
| Outlook COM error | Make sure Outlook desktop is open and signed in |
| M365 data gaps / warnings | Normal — Work IQ may have indexing delays. Agent degrades gracefully. |
| Brief too long / too many items | Check `~/Documents/dayarc/config.json` preferences (max items) |
| Stale priorities showing up | Say "mark X as done" or "drop X" to correct memory |
| No memory on new machine | Copy `~/Documents/dayarc/` from old machine, or start fresh (bootstrap) |

---

## Quick reference

```bash
# Start conversational session
copilot --agent=dayarc

# Example prompts
"What are my priorities today?"
"Show me the PM brief"
"Send me the morning brief"
"What did I work on this week?"
"Mark the auth migration as done"
"Am I forgetting anything?"
"What should I learn about today?"
"Give me a dry run of the weekly report"
```
