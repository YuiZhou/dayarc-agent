---
name: Dayarc Upgrade
description: Check for and apply updates to the Dayarc agent package from GitHub.
---

## When to Use

User asks to update, upgrade, or check for new versions of the agent. Also handles preview upgrades from a feature branch or commit SHA, and rollbacks to stable.

## How It Works

The agent package lives in `~/.dayarc-agent/` and is a git clone of the repo. Upgrades are a fast-forward pull.

Upgrades can target **stable** (`origin/main`, default) or a **preview** ref (branch name or commit SHA).

### Detecting Intent

| User says | Mode |
|---|---|
| "upgrade", "update", "check for updates" | Stable (default) |
| "upgrade to branch `<name>`" | Preview — branch |
| "upgrade to commit `<sha>`" | Preview — commit SHA |
| "upgrade to stable", "rollback", "back to main" | Revert preview → stable |

### Guard Against Local Changes

Before any checkout or pull, run:

```powershell
cd ~/.dayarc-agent
$status = git status --porcelain
if ($status) {
    git stash push -m "dayarc-upgrade auto-stash $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
}
```

If stash fails, tell the user and abort:
> Local changes could not be stashed. Please commit or discard them before upgrading.

### Check for Updates (stable)

```
cd ~/.dayarc-agent
git fetch origin main
```

Compare `HEAD` vs `origin/main`:
- If identical → "Already up to date."
- If behind → show new commits: `git log HEAD..origin/main --oneline`

### Apply Update (stable)

```
git pull --ff-only origin main
```

If fast-forward fails after stashing, tell the user:
> Local changes detected. Run `irm https://raw.githubusercontent.com/YuiZhou/dayarc-agent/main/setup.ps1 | iex` to reinstall cleanly.

Remove the `.preview` marker file if it exists:
```powershell
Remove-Item "$HOME/.dayarc-agent/.preview" -ErrorAction SilentlyContinue
```

### Preview Upgrade (branch or commit SHA)

> ⚠️ **Warning shown to user:** Preview commits are from a feature branch and may be unstable. Your scheduled briefs will run on this preview version until you upgrade to stable.

1. Fetch the target ref:
   ```
   git fetch origin
   ```

2. Resolve the target to a commit:
   - Branch: `git rev-parse origin/<branch>`
   - Commit SHA: use as-is (validate with `git cat-file -t <sha>` — must be `commit`)

3. Detach HEAD at the resolved commit:
   ```
   git checkout --detach <resolved-commit>
   ```

4. Write a `.preview` marker file at `~/.dayarc-agent/.preview`:
   ```
   ref=<branch-name-or-sha>
   commit=<full-commit-sha>
   date=<ISO-8601-timestamp>
   ```

5. Show the user:
   ```
   ⚠️ Preview mode active
   Ref:    <branch-name-or-sha>
   Commit: <short-sha>  <commit-message-first-line>
   To return to stable: say "upgrade to stable"
   ```

### Revert Preview → Stable

When the user says "upgrade to stable", "rollback", or "back to main":

1. Guard local changes (stash as above).
2. `git fetch origin main`
3. `git checkout main && git pull --ff-only origin main`
4. Remove `.preview` marker:
   ```powershell
   Remove-Item "$HOME/.dayarc-agent/.preview" -ErrorAction SilentlyContinue
   ```
5. Proceed with the normal **After Update** steps below.

### Preview Warning on Next Run

At the start of any upgrade or check-for-updates operation, check for `.preview`:

```powershell
$previewFile = "$HOME/.dayarc-agent/.preview"
if (Test-Path $previewFile) {
    $info = Get-Content $previewFile | ConvertFrom-StringData
    Write-Host "⚠️  Running PREVIEW build — ref: $($info.ref), commit: $($info.commit.Substring(0,7))"
    Write-Host "    To return to stable: say 'upgrade to stable'"
}
```

### After Update

1. Read `CHANGELOG.md` and summarize what changed since the previous HEAD.
2. Copy updated files to `~/.copilot/` (agent profile + skills).
3. **Re-register scheduler if this machine owns one:** Read `~/Documents/dayarc/config.json`. The `scheduler` field is an array of `{ machine, am_time, pm_time }` entries. Find the entry where `machine` matches `$env:COMPUTERNAME`. If found, re-register the Task Scheduler tasks with that entry's times:
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
   Read `am_time` and `pm_time` from the matching entry (default: 08:00 / 20:00).
   If no entry matches this machine, skip this step.
4. Report the new version (latest tag or commit short hash). If in preview mode, append ` (preview: <ref>)` to the version string.

### Version

To report current version: `git describe --tags --always` in `~/.dayarc-agent/`.
If `.preview` exists, append `(preview: <ref>)` to the reported version.
