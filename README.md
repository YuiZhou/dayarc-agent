# Dayarc

An AI agent that collects signals from M365 and GitHub, learns your work patterns, and delivers personalized email briefs — powered by Copilot CLI.

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Prerequisites

| Requirement | How to verify |
|-------------|--------------|
| **Copilot CLI** ≥ 1.0.5 | `copilot --version` |
| **GitHub CLI** authenticated | `gh auth status` |
| **M365 session** signed in | Open Outlook desktop |

## Quick Start

```powershell
irm https://raw.githubusercontent.com/YuiZhou/dayarc-agent/main/setup.ps1 | iex
```

This clones the agent, prompts for your identity, and optionally installs the daily scheduler. Then:

```bash
copilot --agent=dayarc
```

To upgrade later: ask `> Update your skills` in a conversation, or re-run the setup one-liner.

To uninstall: `setup.ps1 -uninstall` (user data preserved).

## What It Does

- **PM Brief (8 PM):** Summarizes your day — what you did, tomorrow's priorities, unfinished items
- **AM Brief (8 AM):** Plans your morning — priorities, signals, learning, drift alerts
- **Weekly (Friday):** Themes, accomplishments, stuck items, next week focus
- **Monthly (Last workday):** Time allocation, trends, learning progress, next month outlook

All briefs include source breadcrumbs (links, thread subjects, channel names) for every item.

## Documentation

- [USAGE.md](USAGE.md) — Full usage guide and scenarios
- [design.md](design.md) — Technical architecture
- [spec.md](spec.md) — Product specification
- [memory-schemas.md](memory-schemas.md) — Memory file schemas

## Architecture

```
~/.dayarc-agent/                        (agent package — installed per machine)
├── agents/dayarc.agent.md              Agent identity + rules
├── skills/dayarc-*/SKILL.md            10 skill definitions
├── skills/dayarc-deliver/templates/    4 HTML email templates
├── prompts/{pm,am,weekly,monthly}.md     Plan instructions
├── memory-schemas.md                     Memory file schemas
├── mcp.json                              Work IQ + GitHub MCP servers
└── scheduler.ps1                         Task Scheduler script (optional)

~/Documents/dayarc/                     (user data — synced via OneDrive)
├── config.json                           Identity + preferences
└── memory/                               JSON memory files
```

No custom code. No build step. Just markdown, templates, and two PowerShell scripts.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE).
