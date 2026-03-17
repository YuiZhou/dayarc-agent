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

1. **Install agent package:**

   ```powershell
   git clone https://github.com/YuiZhou/dayarc-agent
   cd dayarc
   $dest = Join-Path $HOME ".dayarc-agent"
   Copy-Item -Recurse agents, skills, prompts, memory-schemas.md, mcp.json, scheduler.ps1 $dest
   ```

2. **Create user config:**

   ```powershell
   mkdir ~/Documents/dayarc
   cp config.example.json ~/Documents/dayarc/config.json
   # Edit config.json with your name, email, GitHub username
   ```

3. **Start conversational session:**

   ```bash
   copilot --agent=dayarc
   ```

4. **(Optional) Install scheduler** for automated daily briefs — see [USAGE.md](USAGE.md#3-optional-scheduler).

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
├── skills/dayarc-*/SKILL.md            9 skill definitions
├── skills/dayarc-deliver/templates/    4 HTML email templates
├── prompts/{pm,am,weekly,monthly}.md     Plan instructions
├── memory-schemas.md                     Memory file schemas
├── mcp.json                              Work IQ + GitHub MCP servers
└── scheduler.ps1                         Task Scheduler script (optional)

~/Documents/dayarc/                     (user data — synced via OneDrive)
├── config.json                           Identity + preferences
└── memory/                               JSON memory files
```

No custom code. No build step. Just markdown, templates, and one PowerShell script.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE).
