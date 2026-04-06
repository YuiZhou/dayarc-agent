# Dayarc Signal Source Connector Interface

Dayarc's COLLECT step is connector-agnostic. Any tool that provides work signals can be plugged in as an MCP server. This document defines the interface contract a connector must satisfy.

---

## What a Connector Is

A connector is an **MCP server** that responds to natural-language queries about a user's work signals. Connectors are declared in `mcp.json` and registered in `config.json` with the signal categories they provide.

The built-in connectors are:
- **`work-iq`** — M365 (Outlook, Teams, SharePoint/OneDrive, Calendar)
- **`github`** — GitHub (PRs, issues, commits, notifications)

Community connectors can provide any subset of the same signal categories.

---

## Signal Categories

Each connector declares which of these categories it provides:

| Category | Description | Used by |
|---|---|---|
| `sent_activity` | Things the user actively did: sent emails, authored PRs/commits, created/commented on issues | PM COLLECT |
| `flagged_items` | Items the user explicitly marked as important (flagged email, starred issue, etc.) | PM + AM COLLECT |
| `saved_items` | Items the user saved for later (Teams saved, bookmarked, etc.) | PM + AM COLLECT |
| `calendar` | Scheduled events and meetings | PM + AM COLLECT |
| `notifications` | Incoming @mentions, review requests, and assignments | AM COLLECT |
| `assigned_items` | Open tasks, tickets, or issues assigned to the user | AM COLLECT |
| `recent_docs` | Files or documents recently edited | PM COLLECT |

---

## Query Contract

For each signal category it provides, a connector **must** be able to answer natural-language queries of these forms:

### `sent_activity`
- "What activity did I author or send since {timestamp}?"
- "What work items did I create or update since {timestamp}?"

### `flagged_items`
- "What items have I flagged or starred?"
- "Show me my high-priority flagged items."

### `saved_items`
- "What items have I saved for later?"

### `calendar`
- "What meetings or events do I have today?"
- "What meetings do I have for the rest of the week?"

### `notifications`
- "What new @mentions or notifications do I have since {timestamp}?"
- "Are there any new review requests or assignments for me since {timestamp}?"

### `assigned_items`
- "What open tasks or issues are currently assigned to me?"

### `recent_docs`
- "What files or documents did I edit since {timestamp}?"

---

## Signal Shape

The signal shape is a **conceptual contract** — it defines what information each signal should carry. The agent reasons about collected signals holistically and does not produce literal JSON arrays between pipeline stages.

When collecting signals, ensure each result has:

| Field | Required | Description |
|---|---|---|
| `description` | ✅ | One sentence describing what the signal is |
| `source_breadcrumb` | ✅ | Link, ticket ID, thread subject, or channel name. Never blank — use `"source unavailable"` as last resort |
| `timestamp` | ✅ | ISO 8601 datetime of last activity |
| `category` | ✅ | One of the signal category names above |
| `connector` | ✅ | Name of the MCP server that provided this signal |

When passing signals to synthesis skills (`classify_activity`, `infer_priorities`, `filter_signals`), present them with these fields so skills can reason about source and relevance correctly.

---

## Declaring a Connector

There are two ways to add a connector:

### Option A — Conversational setup (recommended)

Say to Dayarc: *"I need to connect Jira"* (or ADO, Linear, Slack, etc.).

Dayarc will run the **dayarc-add-connector** skill, which:
1. Asks what you need from the tool (signal categories, your username, project filters, custom requirements)
2. Generates a tailored COLLECT skill and saves it to `~/.copilot/skills/dayarc-connect-{tool}/SKILL.md`
3. Updates `mcp.json` with the MCP server entry (credential placeholders — you fill in the values)
4. Updates `config.json` to register the connector

**This is the recommended path.** The generated skill is saved to `~/.copilot/skills/` — Copilot CLI auto-discovers all skills in this directory on startup, so the new skill becomes immediately available without any additional registration step. This location is not overwritten by Dayarc upgrades, and your connector config is stored in `config.json` so upgrades can re-apply the MCP entry automatically.

### Option B — Manual setup

Follow the steps below to configure a connector by hand.

### 1. Add the MCP server to `mcp.json`

```json
{
  "mcpServers": {
    "work-iq": { "command": "npx", "args": ["-y", "@microsoft/workiq", "mcp"] },
    "github":  { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-github"] },
    "jira":    { "command": "npx", "args": ["-y", "your-jira-mcp-server"] }
  }
}
```

### 2. Register the connector in `config.json`

Add an entry to the `connectors` array with three fields:

| Field | Required | Description |
|---|---|---|
| `name` | ✅ | Must match the key in `mcp.json` |
| `provides` | ✅ | Signal categories this connector supplies |
| `config` | optional | Per-connector user identity and query options (see below) |
| `skill` | optional | Custom COLLECT skill name (see BYO Skill below) |
| `mcp` | optional | MCP server config snapshot — used by `dayarc-upgrade` to re-apply the entry to `mcp.json` after upgrades |

```json
{
  "connectors": [
    {
      "name": "work-iq",
      "provides": ["sent_activity", "flagged_items", "saved_items", "calendar", "recent_docs"]
    },
    {
      "name": "github",
      "provides": ["sent_activity", "notifications", "assigned_items"],
      "config": {
        "usernames": ["your-handle", "your-emu-handle"],
        "notification_reasons": ["mention", "review_requested", "assign"]
      }
    },
    {
      "name": "jira",
      "provides": ["flagged_items", "notifications", "assigned_items"],
      "skill": "dayarc-connect-jira",
      "config": {
        "username": "you@example.com",
        "project_filter": ["PROJ", "INFRA"],
        "notification_reasons": ["mention", "assign"]
      },
      "mcp": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-jira"],
        "env_vars": ["JIRA_URL", "JIRA_EMAIL", "JIRA_API_TOKEN"]
      }
    }
  ]
}
```

If `connectors` is absent from `config.json`, Dayarc falls back to the built-in defaults: `work-iq` for M365 signals, `github` for GitHub signals (using `user.github_usernames` for identity scoping).

#### Standard `config` fields

These field names are conventional — connectors should use them when applicable so users have a consistent configuration experience:

| Field | Type | Meaning |
|---|---|---|
| `usernames` | string[] | User handles/IDs on this platform (used to scope queries to the user's own activity) |
| `username` | string | Single user handle or email, for platforms with one identity |
| `project_filter` | string[] | Restrict signals to these projects, repos, boards, or spaces |
| `notification_reasons` | string[] | Which notification types to fetch (connector-specific values) |
| `issue_types` | string[] | Filter assigned/flagged items to these issue or ticket types |
| `since_field` | string | Name of the timestamp field to use for time-windowed queries (default: `updated`) |

Connectors may define additional tool-specific fields beyond these. Document them in your connector's `README.md`.

---

## How the COLLECT Step Uses Connectors

At COLLECT time, the plan prompt reads `config.json → connectors`, then for each required signal category, queries every connector that lists it under `provides`. The connector's `config` block is passed to scope queries to the right user and context. Synthesis skills (`classify_activity`, `infer_priorities`, `filter_signals`) receive the merged signal set and are unaware of which connector produced each signal.

This means:
- Core skills (`memory`, `classify_activity`, `infer_priorities`, etc.) are unchanged when connectors change.
- Adding a connector only affects the COLLECT step of `pm.md` and `am.md`.
- Removing a connector (e.g., if the user doesn't use M365) degrades gracefully — the brief notes the missing category.

---

## BYO Skill

By default, Dayarc queries a connector using the generic natural-language query forms listed above. You can supply a custom COLLECT skill for more precise control.

**The easiest way to create a BYO skill is to use `dayarc-add-connector` conversationally** — it generates the skill file for you based on your requirements and installs it automatically.

For manual configuration, declare a `skill` in the connector entry:

```json
{
  "name": "jira",
  "provides": ["flagged_items", "notifications", "assigned_items"],
  "skill": "my-jira-collect",
  "config": {
    "username": "you@example.com",
    "project_filter": ["PROJ", "INFRA"]
  }
}
```

When a `skill` is present, the COLLECT step **invokes that skill by name instead of using generic queries** for this connector. The skill receives:

```json
{
  "connector": "jira",
  "provides": ["flagged_items", "notifications", "assigned_items"],
  "config": { "username": "you@example.com", "project_filter": ["PROJ", "INFRA"] },
  "lookback": "today | 7 days",
  "since_timestamp": "ISO 8601"
}
```

The skill must return an array of normalized signals (the signal shape above). It may use any MCP tool available to the agent, including the connector's own MCP server.

**When to use a BYO skill:**
- Your connector's MCP server uses structured queries (not NL) and needs precise parameterization
- You want to filter or enrich signals before they reach synthesis skills
- You need to join data across multiple MCP calls

**Skill location for generated skills:** `dayarc-add-connector` writes skills to `~/.copilot/skills/dayarc-connect-{tool}/SKILL.md`. Copilot CLI auto-discovers all skills in `~/.copilot/skills/` on startup. This location is upgrade-safe — Dayarc upgrades only overwrite skills whose names match the agent package (e.g., `dayarc-*` built-in skills). A generated skill named `dayarc-connect-jira` has a distinct name and will not be overwritten.

**Skill location for community-distributed skills:** Include a `SKILL.md` in your connector's `docs/connector-interface/` contribution (e.g., as an attachment or separate file) and instruct users to place it at `~/.copilot/skills/{skill-name}/SKILL.md`.

---

## Building a Community Connector

To build a community connector:

1. Implement an MCP server that handles the query forms listed above for your tool.
2. Publish it (npm, PyPI, Docker, etc.) so users can install it.
3. Write a doc following the pattern in [`jira.md`](./jira.md):
   - What the connector provides (signal categories)
   - How to install and configure the MCP server
   - What credentials or auth it needs
   - Sample `mcp.json` and `config.json` snippets (including the `config` block with all supported fields)
   - If using a BYO skill, the skill file content and installation instructions
4. Submit a PR to add your doc to `docs/connector-interface/`.

**Naming convention:** `docs/connector-interface/{tool-name}.md`
