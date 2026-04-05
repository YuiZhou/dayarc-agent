# Dayarc — Signal Source Connectors

This document defines the **signal source connector interface** for Dayarc. A connector is an MCP server that provides work signals to the COLLECT step of each brief. Dayarc ships with M365 and GitHub connectors; any MCP server that implements this interface can be added by the community.

---

## 1. What Is a Connector?

A connector is an MCP server declared in the agent profile (`agents/dayarc.agent.md`) that Dayarc queries during the **COLLECT** step of each brief run. The agent issues natural-language queries against the MCP server's tools to gather signals, which are then synthesized into brief sections.

Connectors are **read-only**. Dayarc never issues write actions through a connector.

---

## 2. Signal Types

Each connector declares which signal types it provides. The COLLECT step queries only the signal types a connector covers.

| Signal type | Description | Used by |
|---|---|---|
| `outgoing_messages` | Messages, commits, PRs, or work items the user sent/authored | PM "What I Did" |
| `flagged_items` | User-flagged or saved items awaiting action | AM/PM Priorities |
| `calendar` | Meetings and scheduled events | AM Plan, PM "What I Did" |
| `documents` | Documents or wikis the user edited | PM "What I Did" |
| `incoming_signals` | @mentions, notifications, new messages received | AM Signals |
| `assigned_work` | Issues, PRs, or tasks assigned to the user or awaiting their review | AM Plan |

---

## 3. Connector Declaration

### 3a. Agent Profile (MCP server)

Declare the MCP server in `agents/dayarc.agent.md` frontmatter:

```yaml
mcp-servers:
  my-connector:
    type: stdio
    command: npx
    args: ["-y", "@my-org/my-connector-mcp"]
    tools: ["*"]
```

### 3b. User Config (signal types)

Declare which signal types the connector provides in `~/Documents/dayarc/config.json`:

```json
{
  "connectors": [
    {
      "name": "my-connector",
      "label": "My Connector (e.g. ADO)",
      "provides": ["outgoing_messages", "assigned_work", "incoming_signals"]
    }
  ]
}
```

The `name` field must match the MCP server key in the agent profile frontmatter. If no `connectors` field is present in `config.json`, Dayarc falls back to the built-in defaults (M365 + GitHub).

---

## 4. Query Contract

During COLLECT, the agent issues queries against each connector's MCP server. The queries are natural-language instructions; connector MCP servers must expose tools that can satisfy them. Below are the standard query templates by signal type.

### `outgoing_messages`
> What messages, commits, PRs, or work items did I send, author, or update {LOOKBACK}?

The connector should return a list of items with: description, timestamp, and a link or reference (source breadcrumb).

### `flagged_items`
> What emails, tasks, or items are flagged, starred, or saved for my attention?

The connector should return items the user explicitly marked for follow-up.

### `calendar`
> What meetings or events do I have {date_range}?

The connector should return events with: title, time, attendees (optional), and a link or reference.

### `documents`
> What documents or wiki pages did I edit {LOOKBACK}?

The connector should return edited documents with: title, timestamp, and a link.

### `incoming_signals`
> What @mentions, notifications, or messages did I receive since {cutoff_timestamp}?

The connector should return items that require the user's attention, with: description, sender (if applicable), and a source breadcrumb.

### `assigned_work`
> What issues, PRs, or work items are currently assigned to me or awaiting my review?

The connector should return open items with: title, status, and a link.

---

## 5. Built-in Connectors

### M365 (Work IQ)

| Field | Value |
|---|---|
| `name` | `work-iq` |
| `label` | `M365 (Outlook + Teams + SharePoint)` |
| `provides` | `outgoing_messages`, `flagged_items`, `calendar`, `documents`, `incoming_signals` |
| MCP package | `@microsoft/workiq` |

### GitHub

| Field | Value |
|---|---|
| `name` | `github` |
| `label` | `GitHub` |
| `provides` | `outgoing_messages`, `assigned_work`, `incoming_signals` |
| MCP package | `@modelcontextprotocol/server-github` |

The GitHub connector additionally respects the `github_usernames` array from `config.json` — queries are run for each username to cover personal and EMU/corp accounts.

---

## 6. Adding a Community Connector

1. Find or build an MCP server for your data source.
2. Add the MCP server entry to `agents/dayarc.agent.md` frontmatter (see §3a).
3. Add a connector entry to `~/Documents/dayarc/config.json` with its signal types (see §3b).
4. If you are replacing M365 or GitHub, remove or omit their entries from the `connectors` array.
5. Run a brief to verify signals are collected correctly.

Connectors can **replace** or **supplement** the built-in ones. For example, a Jira connector can provide `assigned_work` while M365 continues to provide `flagged_items` and `calendar`.

**Example — Jira supplementing M365 + GitHub:**
```json
{
  "connectors": [
    { "name": "work-iq",  "label": "M365", "provides": ["outgoing_messages", "flagged_items", "calendar", "documents", "incoming_signals"] },
    { "name": "github",   "label": "GitHub", "provides": ["outgoing_messages", "assigned_work", "incoming_signals"] },
    { "name": "jira",     "label": "Jira", "provides": ["assigned_work", "incoming_signals"] }
  ]
}
```

---

## 7. Graceful Degradation

If a connector's MCP server is unavailable or returns an error during COLLECT, Dayarc notes the gap in the brief and continues with the signals that were successfully collected. No brief is blocked by a single connector failure.

---

## 8. Community Connectors

| Connector | Signal types | See |
|---|---|---|
| Azure DevOps (ADO) | `outgoing_messages`, `assigned_work`, `incoming_signals` | [`connectors/ado/`](./connectors/ado/README.md) |

To add your connector to this list, open a PR with a `connectors/{your-connector}/README.md` following the pattern in `connectors/ado/`.
