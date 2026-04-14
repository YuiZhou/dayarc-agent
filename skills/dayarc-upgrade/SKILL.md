---
name: Dayarc Upgrade
description: Check for and apply updates to the Dayarc agent package from GitHub.
---

## When to Use

User asks to update, upgrade, or check for new versions of the agent — including upgrading to a specific branch or commit, or returning to stable `main`.

## Detecting Install Method

First, determine how Dayarc was installed:

```powershell
# Check plugin install
$pluginHit = Get-ChildItem -Path (Join-Path $HOME ".copilot\installed-plugins") -Filter "plugin.json" -Recurse -ErrorAction SilentlyContinue | Where-Object {
    (Get-Content $_.FullName -Raw | ConvertFrom-Json).name -eq "dayarc"
} | Select-Object -First 1

# Check git clone
$cloneDir = Join-Path $HOME ".dayarc-agent"
$isClone = Test-Path (Join-Path $cloneDir ".git")
```

- **Plugin install** → `$pluginHit` exists → use `copilot plugin update dayarc`
- **Git clone** → `$isClone` is true → use git-based upgrade (below)
- **Neither found** → tell user to reinstall

## Plugin Upgrade

If installed as a plugin, stable upgrades are simple:

```powershell
copilot plugin update dayarc
```

After update, check for scheduler re-registration (see **After Update** section).

Report:
> ✅ Plugin updated. {changelog summary}

**Note:** Stable upgrades always use `copilot plugin update dayarc`. `copilot plugin` only installs published releases — it has no mechanism to install from an arbitrary git branch or commit. Preview branch upgrades therefore fall back to the git clone at `~/.dayarc-agent/` if available (see below).

### Preview Branches with Plugin Install

`copilot plugin` cannot preview a branch — it operates on published/versioned releases only. To run a preview branch alongside a plugin install, the skill uses the git clone at `~/.dayarc-agent/` for git operations while leaving the plugin-managed `~/.copilot/` path untouched.

If the user asks to upgrade to a preview branch or commit while running a plugin install, check whether a git clone also exists:

```powershell
$cloneDir = Join-Path $HOME ".dayarc-agent"
$isClone = Test-Path (Join-Path $cloneDir ".git")
```

- **Clone exists (`$isClone` is true):** Fall through to the **Git Clone Upgrade → Preview Upgrade** path using `~/.dayarc-agent/` for all git operations. However, in the **After Update** step, **skip the "copy files to `~/.copilot/`" sub-step** — the plugin system owns that path and must not be overwritten. Still write the `.preview` marker, re-apply connector MCP entries, re-register the scheduler, and report as normal.

- **Clone does not exist:** Tell the user:
  > Preview branches require a git clone at `~/.dayarc-agent/`. Run the following to set it up, then retry:
  > ```
  > git clone https://github.com/YuiZhou/dayarc-agent ~/.dayarc-agent
  > ```

## Git Clone Upgrade

### Detecting Preview Mode

Check whether `~/.dayarc-agent/.preview` exists. If it does, warn the user:

> ⚠️ **Preview build active** — you are running a pre-release commit (`<contents of .preview>`). This build may be unstable. Say *"upgrade to stable"* to return to `main`.

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
2. **Git clone only:** Copy updated files to `~/.copilot/` (agent profile + skills). Skip for plugin installs — the plugin system handles this.
3. **Re-apply user connector MCP entries:** Read `~/Documents/dayarc/config.json → connectors`. For each connector entry that has an `mcp` field, apply the following logic:

   ```
   Read current mcp.json into $mcpConfig
   For each $connector in config.json → connectors where $connector.mcp exists:
     $name = $connector.name
     If $mcpConfig.mcpServers does NOT have key $name:
       Build new entry:
         command = $connector.mcp.command
         args    = $connector.mcp.args
         env     = { for each var in $connector.mcp.env_vars: $var → "REPLACE_ME" }
       Add $mcpConfig.mcpServers[$name] = new entry
       Mark $name as restored
   Write updated mcp.json back
   ```

   If any connectors were restored, tell the user:
   > ✅ Restored MCP config for connector(s): {restored names}. Your actual credentials were not stored here — check `mcp.json` and replace any `REPLACE_ME` values if needed.

   If `env_vars` is empty or absent for a connector, add the entry with no `env` block.

   Skip this step entirely if no connector in `config.json` has an `mcp` field.

4. **Re-register scheduler if this machine owns one:** Read `~/Documents/dayarc/config.json`. The `scheduler` field is an array of `{ machine, am_time, pm_time }` entries. Find the entry where `machine` matches `$env:COMPUTERNAME`. If found, find the `scheduler.ps1` path (same discovery logic as the scheduler script itself) and re-register:
   ```powershell
   # Find scheduler.ps1 (plugin or clone)
   $pluginHit = Get-ChildItem -Path (Join-Path $HOME ".copilot\installed-plugins") -Filter "scheduler.ps1" -Recurse -ErrorAction SilentlyContinue | Where-Object { (Split-Path $_.DirectoryName -Leaf) -ne "skills" } | Select-Object -First 1
   if ($pluginHit) { $script = $pluginHit.FullName }
   else { $script = Join-Path $HOME ".dayarc-agent\scheduler.ps1" }

   Unregister-ScheduledTask -TaskName "Dayarc-AM" -Confirm:$false -ErrorAction SilentlyContinue
   Unregister-ScheduledTask -TaskName "Dayarc-PM" -Confirm:$false -ErrorAction SilentlyContinue
   $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
   Register-ScheduledTask -TaskName "Dayarc-AM" -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File `"$script`" -trigger am") -Trigger (New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At $amTime) -Settings $settings -Description "Dayarc morning brief"
   Register-ScheduledTask -TaskName "Dayarc-PM" -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File `"$script`" -trigger pm") -Trigger (New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At $pmTime) -Settings $settings -Description "Dayarc evening brief"
   ```
   Read `am_time` and `pm_time` from the matching entry (default: 08:00 / 20:00).
   If no entry matches this machine, skip this step.

   **Note:** The `scheduler.ps1` script auto-detects the correct agent name at runtime (`dayarc:dayarc` for plugin, `dayarc` for user-level). Re-registering the scheduler after a migration from user-level to plugin (or vice versa) is sufficient — no manual agent name changes needed.
5. Report the new version (latest tag or commit short hash).

### Migration: User-Level → Plugin

When upgrading from a user-level install (`~/.dayarc-agent/` + `~/.copilot/skills/dayarc-*`) to a plugin install:

1. The agent name changes from `dayarc` to `dayarc:dayarc`.
2. **The `scheduler.ps1` script handles this automatically** — it detects the install method at startup and uses the correct agent name.
3. After plugin install, **clean up the old user-level files** to avoid confusion:
   ```powershell
   Remove-Item -Path (Join-Path $HOME ".copilot\agents\dayarc.agent.md") -ErrorAction SilentlyContinue
   Get-ChildItem -Path (Join-Path $HOME ".copilot\skills") -Filter "dayarc-*" -Directory | Remove-Item -Recurse -Force
   ```
   If the old `~/.dayarc-agent/` clone is no longer needed:
   ```powershell
   Remove-Item -Path (Join-Path $HOME ".dayarc-agent") -Recurse -Force
   ```
4. Re-register the scheduler tasks (Step 3 above) so the Task Scheduler points to the plugin's `scheduler.ps1`.

### Version

- **Git clone:** `git describe --tags --always` in `~/.dayarc-agent/`.
- **Plugin:** `copilot plugin list` or read `plugin.json` version field.
