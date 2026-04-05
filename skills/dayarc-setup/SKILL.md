---
name: Dayarc Setup
description: Initialize Dayarc data directories, user config, and optional scheduler on first run or reconfiguration.
---

## When to Use

- Automatically triggered when `~/Documents/dayarc/config.json` does not exist (first run after install).
- Explicitly triggered when the user asks to "set up", "reconfigure", "reset config", or "reinitialize" Dayarc.

## Preflight Checks

Before starting setup, verify prerequisites:

### 1. GitHub CLI

```powershell
gh auth status
```

- **If not authenticated:** Stop and tell the user:
  > I need GitHub authentication to access your data. Please run `gh auth login` first, then come back.

### 2. Outlook (soft check)

```powershell
Get-Process OUTLOOK -ErrorAction SilentlyContinue
```

- **If not running:** Warn but continue:
  > ⚠️ Outlook isn't running. You'll need it later for email briefs, but we can finish setup without it.

## Setup Steps

### Step 1: Create Data Directories

```powershell
$docsDir = [Environment]::GetFolderPath("MyDocuments")
$dataDir = Join-Path $docsDir "dayarc"
```

**OneDrive detection:** Check if `$docsDir` differs from `$HOME\Documents`. If so, OneDrive is redirecting the Documents folder. Ask the user:

> Your Documents folder is managed by OneDrive (`{docsDir}`). Is this the first machine you're setting up Dayarc on?

- **First machine → create directories:**
  ```powershell
  New-Item -ItemType Directory -Path (Join-Path $dataDir "memory\daily") -Force
  New-Item -ItemType Directory -Path (Join-Path $dataDir "memory\runs") -Force
  New-Item -ItemType Directory -Path (Join-Path $dataDir "memory\weekly-archive") -Force
  ```

- **Not first machine →** Tell the user to wait for OneDrive sync, then re-launch.

If no OneDrive detected, create directories immediately.

### Step 2: Collect Identity

Ask the user for four pieces of information, one at a time:

1. **Full name** — "What's your full name as it appears in @mentions? (e.g., Yu Zhou — not a nickname)"
2. **Work email** — "What's your work email address?"
3. **GitHub username(s)** — "What are your GitHub usernames? (comma-separated if you have multiple, e.g., personal + enterprise/EMU account)"
4. **Preferred language** — "What language would you like your briefs in? Type `en` for English or `zh` for Chinese (简体中文). Default is `en`."

### Step 3: Write config.json

Write to `~/Documents/dayarc/config.json`:

```json
{
  "user": {
    "display_name": "<name from Step 2>",
    "email": "<email from Step 2>",
    "github_usernames": ["<handle1>", "<handle2>"]
  },
  "locale": "<locale from Step 2, default 'en'>",
  "preferences": {
    "brief_max_items": 15,
    "priority_max_items": 5,
    "unfinished_max_items": 5,
    "signal_max_items": 10,
    "plan_max_items": 8,
    "learning_items": 5,
    "drift_max_items": 3
  },
  "scheduler": []
}
```

Confirm to the user: "✅ Config saved to `~/Documents/dayarc/config.json`"

### Step 4: Offer Scheduler Registration

Ask: "Would you like to register daily briefs with Task Scheduler? (AM at 8:00 + PM at 20:00, weekdays only)"

If yes:

1. **Find the scheduler script.** Search for `scheduler.ps1` in these locations, in order:
   ```powershell
   # Plugin install location
   $pluginHits = Get-ChildItem -Path (Join-Path $HOME ".copilot\installed-plugins") -Filter "scheduler.ps1" -Recurse -ErrorAction SilentlyContinue
   # Git clone location
   $cloneHit = Join-Path $HOME ".dayarc-agent\scheduler.ps1"
   ```
   Use the first hit that exists. If none found, tell the user and skip.

   **Agent name:** The scheduler script auto-detects the correct agent name at runtime (`dayarc:dayarc` for plugin installs, `dayarc` for user-level). No manual configuration needed.

2. **Register scheduled tasks:**
   ```powershell
   $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
   Register-ScheduledTask -TaskName "Dayarc-AM" -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File `"$schedulerScript`" -trigger am") -Trigger (New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 8:00AM) -Settings $settings -Description "Dayarc morning brief"
   Register-ScheduledTask -TaskName "Dayarc-PM" -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File `"$schedulerScript`" -trigger pm") -Trigger (New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 8:00PM) -Settings $settings -Description "Dayarc evening brief"
   ```

3. **Update config.json** — add this machine to the scheduler array:
   ```json
   { "machine": "<COMPUTERNAME>", "am_time": "08:00", "pm_time": "20:00" }
   ```

If no: skip and tell the user they can add it later by saying "set up scheduler".

### Step 5: Offer Dry-Run Preview

Ask: "Want to see a preview brief now? It won't send email or write any data — just shows what your brief would look like."

If yes, run the PM brief in dry-run mode. Prepend this header to the pm.md prompt content:

```
## DRY RUN MODE
This is a preview. Follow the plan below but: skip the idempotency check, do NOT send email (skip Step 5), do NOT write memory files or run tags (skip Step 4). Output the brief to the terminal only. After displaying the brief, ask if the user wants to adjust anything.
```

If no: tell the user their first real brief arrives at 8 PM tonight (if scheduler is registered) or they can say "run PM brief" anytime.

## Completion Message

After all steps:

```
╔══════════════════════════════════════╗
║        Dayarc is ready ✅            ║
╚══════════════════════════════════════╝

  Data:      ~/Documents/dayarc/
  Scheduler: {Registered / Not registered}
  Start:     Just ask me anything about your work!
```
