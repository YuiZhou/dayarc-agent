# Summary — Issue #16: Pluggable Signal Source Connectors (PR #77 iteration 2)

## What changed and why

### PR review feedback addressed
> "I am thinking: user: I need to connect Jira with requirement X,X,X → Dayarc: I will create a skill/prompt for you and update config.json. The skill/prompt will be saved at a place that won't be reset during upgrade."

The reviewer wants a **conversational connector setup flow** with upgrade-safe skill persistence.

### 1. `skills/dayarc-add-connector/SKILL.md` (new)
A new skill that implements the conversational setup flow:
- **Phase 1 — Collect:** Asks the user (one question at a time) for tool name, MCP package, signal categories, their identity on the platform, project filters, and any custom query requirements
- **Phase 2 — Generate:** Produces a custom COLLECT `SKILL.md` tailored to the user's requirements, with per-category query instructions baked in
- **Phase 3 — Install:** Writes the generated skill to `~/.copilot/skills/dayarc-connect-{tool}/SKILL.md` — upgrade-safe because Dayarc upgrades only overwrite skills sourced from the agent package
- **Phase 4 — Register:** Updates `mcp.json` with the MCP server entry (credential placeholders); updates `config.json` with `name`, `provides`, `skill`, `config`, and `mcp` fields
- **Phase 5 — Confirm:** Shows the user a summary of what was configured

### 2. `skills/dayarc-upgrade/SKILL.md` (modified)
Added a new step to **After Update**: re-apply connector MCP entries from `config.json → connectors[].mcp` back into `mcp.json` after a pull. This means the MCP server registration survives upgrades — the `mcp` field in `config.json` (which lives in user data and is never overwritten by upgrades) is the source of truth for restoring it.

### 3. `connectors/CONNECTOR-INTERFACE.md` (modified)
- Added "Option A — Conversational setup (recommended)" section pointing to `dayarc-add-connector`
- Documented the `mcp` field on connector entries (stores MCP config for upgrade re-application)
- Updated BYO Skill section to note that `dayarc-add-connector` generates skills automatically
- Updated skill location docs to distinguish generated skills (`~/.copilot/skills/`) from community-distributed skills

### 4. `agents/dayarc.agent.md` (modified)
Added trigger rule for `dayarc-add-connector`: fires when user says "connect X", "add connector for X", "set up X integration", "I want Dayarc to check my X".

### 5. `design.md` (modified)
Updated §1a to describe the conversational setup flow, generated skill location, and upgrade-safety mechanism.

## Spec / design sections supporting the change

- **spec.md §5 Data Sources** — Extensible signal sources, now with a first-class conversational onboarding flow
- **design.md §1 Architecture** — Agent package vs user data separation: generated skills go to `~/.copilot/skills/` (not agent package); MCP config goes to `config.json` (user data, OneDrive-synced, upgrade-safe)
- **design.md §3 Plans** — Only COLLECT varies; synthesis unchanged
