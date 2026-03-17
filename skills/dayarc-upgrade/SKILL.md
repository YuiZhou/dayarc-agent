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
3. Report the new version (latest tag or commit short hash).

### Version

To report current version: `git describe --tags --always` in `~/.dayarc-agent/`.
