# Changelog

## [Unreleased] — 2026-03-17

### Added
- `plugin.json` — Copilot CLI plugin manifest; enables `copilot plugin install YuiZhou/dayarc-agent`
- `dayarc-setup` skill — Agent-guided interactive setup on first launch (creates dirs, collects identity, writes config.json, offers scheduler)
- `setup.ps1` — One-line installer (`irm .../setup.ps1 | iex`), upgrade, and uninstall
- `setup.ps1` dry-run offer — After install, prompts user to preview their first brief (reuses `pm.md` with side effects disabled)
- `dayarc-upgrade` skill — Conversational agent updates ("Update your skills")
- `dayarc-report-issue` skill — File bug reports and feature requests on the Dayarc repo
- `.github/ISSUE_TEMPLATE/` — Bug report and feature request templates
- Triage labels: triaged, low-risk, high-risk, needs-review, approved, auto-fix, duplicate, question
- Triage bot (`triage.yml`) — Auto-classifies new issues via Copilot CLI in GitHub Actions
- `.github/prompts/triage-prompt.md` — Triage classification prompt
- Coding agent (`coding-agent.yml`) — Auto-generates fix PRs when maintainer labels issue `approved`
- `.github/prompts/coding-prompt.md` — Coding agent prompt with scope guard rules
- CI scope-guard job — Validates `auto-fix` PRs only modify allowed files
- Re-run detection: existing install → `git pull`, existing config → skip prompts

### Changed
- Renamed the product, agent package, skill paths, prompts, scheduler task names, and document paths from Briefing to Dayarc
- **First-run detection** in agent profile: checks for `config.json` on every conversation start; triggers setup skill if missing
- **Plugin-first install flow**: `copilot plugin install` + first launch replaces the two-step install
- `scheduler.ps1` now discovers agent dir dynamically (plugin or git clone)
- `dayarc-upgrade` skill supports both plugin updates and git-based upgrades
- Installation docs rewritten for plugin-first flow
- Agent now has 12 skills (was 9)

### Fixed
- **#68 — Scheduler breaks on plugin migration:** `scheduler.ps1` now auto-detects the correct agent name (`dayarc:dayarc` for plugin installs, `dayarc` for user-level). Previously hardcoded `--agent=dayarc` which failed after migrating to plugin install.
- `setup.ps1` dry-run and completion message now use the correct agent name for the detected install method.
- `dayarc-upgrade` skill documents the user-level → plugin migration path including agent name change and old file cleanup.

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
