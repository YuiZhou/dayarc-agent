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

### Plugin install (recommended)

```bash
copilot plugin install YuiZhou/dayarc-agent
copilot --agent=dayarc:dayarc
```

On first launch, the agent detects it hasn't been configured and walks you through setup interactively — creating your data folder, asking for your identity, and optionally registering the daily scheduler. No separate setup script needed.

### Setup script (alternative)

If you prefer a non-interactive script that does everything in one pass:

```powershell
irm https://raw.githubusercontent.com/YuiZhou/dayarc-agent/main/setup.ps1 | iex
```

This clones the agent, registers skills, prompts for your identity, and optionally installs the daily scheduler.

### Uninstall

```powershell
# Plugin uninstall
copilot plugin uninstall dayarc

# Or: remove scheduler + agent dir (user data preserved)
$setup = (Invoke-WebRequest https://raw.githubusercontent.com/YuiZhou/dayarc-agent/main/setup.ps1).Content
& ([scriptblock]::Create($setup)) -uninstall
```

Removes scheduler tasks and agent directory. User data (`~/Documents/dayarc/`) is preserved.

### Upgrade

| Method | How |
|--------|-----|
| **Plugin update** | `copilot plugin update dayarc` |
| **Conversational** | Start `copilot --agent=dayarc:dayarc` and say `upgrade` |
| **Re-run setup** | `irm .../setup.ps1 \| iex` — detects existing install, does `git pull`, skips config |

### Migrate to a new machine

User data syncs automatically via OneDrive — just install the plugin on the new machine:

```bash
copilot plugin install YuiZhou/dayarc-agent
copilot --agent=dayarc:dayarc     # agent detects synced data, skips setup
# Then: gh auth login + sign in to Outlook
```

Memory, config, and preferences are already there via OneDrive.

### What gets installed

```
~/.copilot/installed-plugins/.../dayarc/  (agent package — via plugin install)
├── agents/dayarc.agent.md
├── skills/dayarc-*/SKILL.md              12 skill definitions (incl. setup)
├── skills/dayarc-deliver/templates/      4 HTML + 4 Markdown brief templates
├── prompts/{pm,am,weekly,monthly}.md
├── memory-schemas.md
├── mcp.json
├── scheduler.ps1
└── setup.ps1

~/Documents/dayarc/                       (user data — OneDrive synced)
├── config.json                           Identity + preferences
└── memory/                               JSON memory files
```

---

## How to Use

> **Agent name:** Plugin installs use `--agent=dayarc:dayarc`. Script installs use `--agent=dayarc`. All examples below use the plugin form. If you installed via `setup.ps1`, drop the `dayarc:` prefix.

### Conversational mode (default)

Start a Copilot CLI session with Dayarc:

```bash
copilot --agent=dayarc:dayarc
```

Then ask anything in natural language. The agent reads your memory and queries live data to answer.

**No emails sent, no memory written** — conversational mode is read-only by default.

---

## Scenarios

### 🔍 Ask about priorities

```
copilot --agent=dayarc:dayarc

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

The scheduler is registered during setup (either agent-guided or via setup.ps1). It creates two Task Scheduler entries:

- **Dayarc-AM** — 8:00 AM, Mon–Fri
- **Dayarc-PM** — 8:00 PM, Mon–Fri

To manage manually:

```powershell
# Check status
Get-ScheduledTask -TaskName "Dayarc-AM","Dayarc-PM" | Format-Table TaskName, State

# Unregister
Unregister-ScheduledTask -TaskName "Dayarc-AM" -Confirm:$false
Unregister-ScheduledTask -TaskName "Dayarc-PM" -Confirm:$false

# Re-register (ask the agent)
copilot --agent=dayarc:dayarc
> Set up the scheduler
```

Scheduled runs are **authoritative**: they deliver to all configured targets (email, GitHub issues, etc.), write memory, and write run tags. If a scheduled run already completed for a given date+type, it won't re-deliver (idempotent).

### Delivery Targets

By default, briefs are sent via email. You can add additional delivery targets in `config.json`:

```json
{
  "delivery": [
    { "target": "email", "briefs": ["pm", "am", "weekly", "monthly"] },
    { "target": "github-issue", "briefs": ["weekly"],
      "config": { "repo": "owner/repo", "labels": ["weekly-brief"] } }
  ]
}
```

**Available targets:**
- `email` — Send HTML email via Outlook COM (default)
- `github-issue` — Create a GitHub issue with Markdown content via `gh` CLI

Each target is independent — if one fails, others still deliver. The delivery summary reports success/failure per target.

> ⚠️ **Privacy:** GitHub issues may be visible depending on repo settings. Use a private repo for briefs containing sensitive work data.

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
copilot --agent=dayarc:dayarc

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
