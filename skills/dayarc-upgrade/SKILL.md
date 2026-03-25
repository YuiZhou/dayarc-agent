---
name: Dayarc Upgrade
description: Check for and apply updates to the Dayarc agent package from GitHub.
---

## When to Use

User asks to update, upgrade, or check for new versions of the agent — including upgrading to a specific branch or commit, or returning to stable `main`.

## Detecting Preview Mode

At the start of every run, check whether `~/.dayarc-agent/.preview` exists. If it does, warn the user:

> ⚠️ **Preview build active** — you are running a pre-release commit (`<contents of .preview>`). This build may be unstable. Say *"upgrade to stable"* to return to `main`.

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

### Apply Update (stable, default)

```
git pull --ff-only origin main
```

If fast-forward fails (local modifications), tell the user:
> Local changes detected. Run `irm https://raw.githubusercontent.com/YuiZhou/dayarc-agent/main/setup.ps1 | iex` to reinstall cleanly.

After a successful stable update, if `~/.dayarc-agent/.preview` exists, delete it.

### Preview Upgrade (branch or commit)

Triggered when the user says something like:
- *"upgrade to branch feat/triage-bot"*
- *"upgrade to commit abc1234"*
- *"preview branch feat/new-feature"*

Steps:

1. **Warn** the user upfront:
   > ⚠️ Preview builds may be unstable and are not suitable for production use. Proceed?

   Wait for explicit confirmation ("yes" / "ok" / "proceed"). If the user does not confirm, abort.

2. **Guard local changes** — stash any uncommitted changes first:
   ```powershell
   cd ~/.dayarc-agent
   git stash --include-untracked
   ```
   Note the stash result. If the working tree is clean, note that too (nothing to stash).

3. **Fetch the ref**:
   ```powershell
   git fetch origin <branch-or-sha>
   ```
   If the ref looks like a branch name (not a 40-char or abbreviated hex SHA), fetch it as:
   ```powershell
   git fetch origin refs/heads/<branch>:refs/remotes/origin/<branch>
   ```

4. **Resolve to a commit SHA**:
   ```powershell
   git rev-parse FETCH_HEAD
   ```

5. **Detach HEAD to that commit**:
   ```powershell
   git checkout --detach FETCH_HEAD
   ```

6. **Write the `.preview` marker** with the ref description and resolved SHA:
   ```
   feat/triage-bot @ abc1234f
   ```
   Full path: `~/.dayarc-agent/.preview`

7. **Run After Update steps** (copy files, re-register scheduler if applicable).

8. **Report**:
   > ✅ Now running preview: `feat/triage-bot @ abc1234f`. Say *"upgrade to stable"* to return to `main`.

If `git fetch` or `git checkout` fails (e.g., invalid ref), tell the user the ref could not be found and abort without modifying any files.

### Return to Stable

Triggered when the user says *"upgrade to stable"*, *"rollback"*, or *"go back to main"*.

```powershell
cd ~/.dayarc-agent
git fetch origin main
git checkout main
git pull --ff-only origin main
Remove-Item -Path ".preview" -ErrorAction SilentlyContinue
```

Then run **After Update** steps as normal. Report:
> ✅ Restored to stable `main`. Preview mode cleared.

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
4. Report the new version (latest tag or commit short hash).

### Version

To report current version: `git describe --tags --always` in `~/.dayarc-agent/`.
