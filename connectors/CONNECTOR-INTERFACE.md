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

Regardless of source, all collected signals are normalized into this shape before being passed to synthesis skills:

```json
{
  "description": "One-sentence description of the signal",
  "source_breadcrumb": "link, ticket ID, thread subject, or channel name",
  "timestamp": "ISO 8601 datetime",
  "category": "sent_activity | flagged_items | saved_items | calendar | notifications | assigned_items | recent_docs",
  "connector": "name of the MCP server that provided this signal"
}
```

The `source_breadcrumb` field is **required**. If a connector cannot provide a stable link, it must provide the best available identifier (ticket number, thread subject, channel name). Never leave it blank — use `"source unavailable"` as a last resort.

---

## Declaring a Connector

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
      "config": {
        "username": "you@example.com",
        "project_filter": ["PROJ", "INFRA"],
        "notification_reasons": ["mention", "assign"]
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

By default, Dayarc queries a connector using the generic natural-language query forms listed above. If your connector works better with a custom COLLECT logic, declare a `skill` in the connector entry:

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

**Skill location:** Deliver the skill as a `SKILL.md` in a `skills/` subdirectory of your connector directory (e.g., `connectors/jira/skills/my-jira-collect/SKILL.md`) and instruct users to copy it to their `~/.copilot/skills/` folder.

---

## Building a Community Connector

To build a community connector:

1. Implement an MCP server that handles the query forms listed above for your tool.
2. Publish it (npm, PyPI, Docker, etc.) so users can install it.
3. Write a `README.md` following the pattern in [`connectors/jira/README.md`](./jira/README.md):
   - What the connector provides (signal categories)
   - How to install and configure the MCP server
   - What credentials or auth it needs
   - Sample `mcp.json` and `config.json` snippets (including the `config` block with all supported fields)
   - If using a BYO skill, instructions for installing it
4. Submit a PR to add your connector directory under `connectors/`.

**Naming convention:** `connectors/{tool-name}/README.md`

If using a BYO skill, also include: `connectors/{tool-name}/skills/{skill-name}/SKILL.md`
