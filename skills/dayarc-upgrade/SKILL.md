---
name: Dayarc Upgrade
description: Check for and apply updates to the Dayarc agent package from GitHub.
---

## When to Use

User asks to update, upgrade, or check for new versions of the agent.

## How It Works

The agent package lives in `~/.dayarc-agent/` and is a git clone of the repo. Upgrades are a fast-forward pull.

### Check for Updates

```
cd ~/.dayarc-agent
git fetch origin main
```

Compare `HEAD` vs `origin/main`:
- If identical → "Already up to date."
- If behind → show new commits: `git log HEAD..origin/main --oneline`

### Apply Update

```
git pull --ff-only origin main
```

If fast-forward fails (local modifications), tell the user:
> Local changes detected. Run `irm https://raw.githubusercontent.com/YuiZhou/dayarc-agent/main/setup.ps1 | iex` to reinstall cleanly.

### After Update

1. Read `CHANGELOG.md` and summarize what changed since the previous HEAD.
2. Copy updated files to `~/.copilot/` (agent profile + skills).
3. **Re-register scheduler if enabled:** Read `~/Documents/dayarc/config.json`. If `scheduler.enabled` is `true`, re-register the Task Scheduler tasks to pick up any script changes:
   ```powershell
   $script = Join-Path $HOME ".dayarc-agent" "scheduler.ps1"
   # Unregister old tasks
   Unregister-ScheduledTask -TaskName "Dayarc-AM" -Confirm:$false -ErrorAction SilentlyContinue
   Unregister-ScheduledTask -TaskName "Dayarc-PM" -Confirm:$false -ErrorAction SilentlyContinue
   # Re-register with updated script
   $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
   Register-ScheduledTask -TaskName "Dayarc-AM" -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File `"$script`" -trigger am") -Trigger (New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At $amTime) -Settings $settings -Description "Dayarc morning brief"
   Register-ScheduledTask -TaskName "Dayarc-PM" -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File `"$script`" -trigger pm") -Trigger (New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At $pmTime) -Settings $settings -Description "Dayarc evening brief"
   ```
   Read `scheduler.am_time` and `scheduler.pm_time` from config.json for the trigger times (default: 08:00 / 20:00).
   If `scheduler.enabled` is `false` or missing, skip this step.
4. Report the new version (latest tag or commit short hash).

### Version

To report current version: `git describe --tags --always` in `~/.dayarc-agent/`.
