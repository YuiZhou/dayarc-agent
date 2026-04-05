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

Add an entry to the `connectors` array, listing the signal categories it provides:

```json
{
  "connectors": [
    {
      "name": "work-iq",
      "provides": ["sent_activity", "flagged_items", "saved_items", "calendar", "recent_docs"]
    },
    {
      "name": "github",
      "provides": ["sent_activity", "notifications", "assigned_items"]
    },
    {
      "name": "jira",
      "provides": ["flagged_items", "notifications", "assigned_items"]
    }
  ]
}
```

The `name` must match the key in `mcp.json`.

If `connectors` is absent from `config.json`, Dayarc falls back to the built-in defaults: `work-iq` for M365 signals, `github` for GitHub signals.

---

## How the COLLECT Step Uses Connectors

At COLLECT time, the plan prompt reads `config.json → connectors`, then for each required signal category, queries every connector that lists it under `provides`. Synthesis skills (`classify_activity`, `infer_priorities`, `filter_signals`) receive the merged signal set and are unaware of which connector produced each signal.

This means:
- Core skills (`memory`, `classify_activity`, `infer_priorities`, etc.) are unchanged when connectors change.
- Adding a connector only affects the COLLECT step of `pm.md` and `am.md`.
- Removing a connector (e.g., if the user doesn't use M365) degrades gracefully — the brief notes the missing category.

---

## Building a Community Connector

To build a community connector:

1. Implement an MCP server that handles the query forms listed above for your tool.
2. Publish it (npm, PyPI, Docker, etc.) so users can install it.
3. Write a `README.md` following the pattern in [`connectors/jira/README.md`](./jira/README.md):
   - What the connector provides (signal categories)
   - How to install and configure the MCP server
   - What credentials or auth it needs
   - Sample `mcp.json` and `config.json` snippets
4. Submit a PR to add your connector directory under `connectors/`.

**Naming convention:** `connectors/{tool-name}/README.md`
