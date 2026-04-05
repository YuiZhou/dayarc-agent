# Changelog

## [Unreleased] — 2026-04-05

### Added
- `connectors/CONNECTOR-INTERFACE.md` — Signal source interface spec: defines signal categories, query contract, signal shape, and how to declare/register a connector; documents `config` fields, `skill` (BYO skill), and `mcp` (upgrade-preservation) fields; documents conversational setup via `dayarc-add-connector`
- `connectors/jira/README.md` — Community Jira connector example (provides `flagged_items`, `notifications`, `assigned_items`); includes `config` field table and "Advanced: BYO Skill" section
- `skills/dayarc-add-connector` — Conversational connector setup skill: collects requirements, generates a custom COLLECT skill, writes it to `~/.copilot/skills/dayarc-connect-{tool}/` (upgrade-safe), updates `mcp.json` and `config.json`
- `config.example.json` — Added `connectors` array with `config` blocks; connector entries support `skill`, `config`, and `mcp` fields

### Changed
- `prompts/pm.md` — COLLECT step refactored to be connector-agnostic: reads active connectors from `config.json → connectors`, dispatches to BYO skill when declared, queries each connector using its `config` block for identity/filter scoping; falls back to Work IQ + GitHub defaults if `connectors` is absent
- `prompts/am.md` — Same connector-agnostic refactor for AM COLLECT step
- `design.md` — Architecture section updated with pluggable connector model (§1a), including conversational setup flow and upgrade-safety design
- `skills/dayarc-upgrade` — After Update step now re-applies user connector MCP entries from `config.json → connectors[].mcp` back into `mcp.json` after a pull (upgrade-safe connector persistence)
- `agents/dayarc.agent.md` — Added `dayarc-add-connector` trigger rule

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
- Coding agent `/continue` with **session resume** — Post `/continue` on a PR to resume the original Copilot session (via `actions/cache` + `--resume`); agent has full memory of prior reasoning and reads PR feedback directly via GitHub MCP tools
- `.github/prompts/coding-prompt.md` — Coding agent prompt (supports new + continue modes)
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
- **#68 — Scheduler breaks on plugin migration:** Three issues in `scheduler.ps1`:
  1. Agent name: now auto-detects `dayarc:dayarc` (plugin) vs `dayarc` (user-level)
  2. Missing `--allow-all`: scheduled (non-interactive) runs now pass `--allow-all` so the agent can use tools
  3. No logging: output now written to `~/Documents/dayarc/logs/{date}-{trigger}.log` via `Tee-Object`
- `setup.ps1` dry-run and completion message now use the correct agent name for the detected install method.
- `dayarc-upgrade` skill documents the user-level → plugin migration path including agent name change and old file cleanup.

### Removed
- **Scope guard** — file-level restrictions on coding agent removed. Human merge review is the safety gate. (#70)
- CI `scope-guard` job removed from `ci.yml`

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
