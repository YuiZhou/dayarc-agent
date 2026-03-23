# Changelog

## [Unreleased] — 2026-03-17

### Added
- `setup.ps1` — One-line installer (`irm .../setup.ps1 | iex`), upgrade, and uninstall
- `dayarc-upgrade` skill — Conversational agent updates ("Update your skills")
- `dayarc-report-issue` skill — File bug reports and feature requests on the Dayarc repo
- `.github/ISSUE_TEMPLATE/` — Bug report and feature request templates
- Triage labels: triaged, low-risk, high-risk, needs-review, approved, auto-fix, duplicate, question
- Re-run detection: existing install → `git pull`, existing config → skip prompts

### Changed
- Renamed the product, agent package, skill paths, prompts, scheduler task names, and document paths from Briefing to Dayarc
- Installation docs rewritten for one-line setup
- Agent now has 11 skills (was 9)

## [1.0.0] — 2026-03-17

### Changed
- **Architecture rewrite:** Replaced custom TypeScript agent with pure Copilot CLI architecture
- Agent is now defined entirely in markdown — skills, plans, and templates
- No build step, no dependencies, no custom code

### Added
- `agents/dayarc.agent.md` — Agent identity and rules
- 9 skill definitions (`skills/dayarc-*/SKILL.md`)
- 4 plan prompts (`prompts/{pm,am,weekly,monthly}.md`)
- `memory-schemas.md` — Memory file schema reference
- `mcp.json` — Work IQ + GitHub MCP server configuration
- `scheduler.ps1` — Optional Windows Task Scheduler script

### Removed
- All TypeScript source code (`src/`)
- Build toolchain (`tsconfig.json`, `vitest.config.ts`)
- Node.js dependencies (`node_modules/`, `package-lock.json`)

## [0.1.0] — 2026-03-14

- Initial open-source release
- PM and AM briefs with TypeScript agent
- Work IQ and GitHub MCP integration
- Layered memory system (daily → weekly → monthly)
- Outlook COM email delivery
- Conversational query mode
