# Contributing

Thank you for your interest in contributing to Dayarc!

## Project Structure

This project contains **no code** — only markdown definitions consumed by Copilot CLI:

```
agents/           Agent profile (dayarc.agent.md)
skills/           9 skill definitions (SKILL.md files)
prompts/          4 plan prompts (pm.md, am.md, weekly.md, monthly.md)
memory-schemas.md Memory file schema reference
mcp.json          MCP server configuration
scheduler.ps1     Optional Windows Task Scheduler script
config.example.json  User config template
```

## How to Contribute

### Editing skills
Each skill is a `SKILL.md` file under `skills/dayarc-*/`. Skills define input, output, and instructions for the agent.

### Editing plan prompts
Plan prompts in `prompts/` are step-by-step instructions the agent follows during scheduled runs.

### Editing templates
HTML email templates are Handlebars (`.hbs`) files in `skills/dayarc-deliver/templates/`.

### Testing changes
Test by running Copilot CLI with Dayarc:

```bash
copilot --agent=dayarc
# Then ask: "Show me a dry run of the PM brief"
```

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b my-feature`)
3. Make your changes
4. Test with Copilot CLI
5. Commit your changes
6. Push to your fork and open a PR against `main`

## Style Guidelines

- Skills: follow the SKILL.md format (YAML frontmatter + Input/Output/Instructions)
- Plans: step-by-step numbered instructions, clear and unambiguous
- Templates: inline CSS only (email compatibility)
