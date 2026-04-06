# Jira Connector for Dayarc

Community connector that brings Jira signals into Dayarc briefs — assigned issues, @mentions, and priority items.

**Signal categories provided:** `flagged_items`, `notifications`, `assigned_items`

> **Status:** Community example. Test with your Jira instance and report issues at [YuiZhou/dayarc-agent](https://github.com/YuiZhou/dayarc-agent).

---

## What It Adds to Your Briefs

| Brief section | What Jira adds |
|---|---|
| **AM — Today's Plan** | Jira issues assigned to you, sorted by priority |
| **AM — Signals Worth Noting** | New @mentions in Jira comments since last brief |
| **AM — Today's Plan** | Issues flagged/starred by you |
| **PM — Tomorrow's Priorities** | Overdue or high-priority assigned issues |

Jira does **not** provide `sent_activity`, `calendar`, or `recent_docs`. Those still come from your other configured connectors (e.g., Work IQ or Google Workspace).

---

## Prerequisites

- A Jira Cloud or Jira Data Center account
- A Jira API token: [Manage API tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
- Node.js ≥ 18 (to run the MCP server via npx)

---

## Installation

### Step 1 — Install the MCP server

This connector uses the `@modelcontextprotocol/server-jira` community MCP server (or a compatible alternative).

> **Note:** `@modelcontextprotocol/server-jira` is used here as an example package name. Check [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) or your Jira tool's community for the actual published package. If no official package exists yet, any MCP server that satisfies the query contract in [README.md](./README.md) will work.

```powershell
# Verify it's available
npx -y @modelcontextprotocol/server-jira --version
```

### Step 2 — Add to `mcp.json`

Open `~/.dayarc-agent/mcp.json` (git clone install) or the plugin's `mcp.json` and add the `jira` entry:

```json
{
  "mcpServers": {
    "work-iq": { "command": "npx", "args": ["-y", "@microsoft/workiq", "mcp"] },
    "github":  { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-github"] },
    "jira": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-jira"],
      "env": {
        "JIRA_URL": "https://your-org.atlassian.net",
        "JIRA_EMAIL": "you@example.com",
        "JIRA_API_TOKEN": "your-api-token"
      }
    }
  }
}
```

> ⚠️ **Do not commit `mcp.json` with your API token.** Use environment variables or a secrets manager. The `env` block above sets process-level env vars at MCP server startup — keep `mcp.json` out of version control.

### Step 3 — Register in `config.json`

Open `~/Documents/dayarc/config.json` and add `jira` to the `connectors` array with a `config` block scoped to your identity and projects:

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
        "usernames": ["your-github-handle"]
      }
    },
    {
      "name": "jira",
      "provides": ["flagged_items", "notifications", "assigned_items"],
      "config": {
        "username": "you@example.com",
        "project_filter": ["PROJ", "INFRA"],
        "notification_reasons": ["mention", "assign"],
        "issue_types": ["Bug", "Story", "Task"]
      }
    }
  ]
}
```

#### Jira `config` fields

| Field | Default | Description |
|---|---|---|
| `username` | — | Your Jira email or username. Used to scope @mention queries to you. **Required** for `notifications`. |
| `project_filter` | all projects | Restrict signals to these Jira project keys (e.g., `["PROJ", "INFRA"]`). Omit to query all projects you have access to. |
| `notification_reasons` | `["mention", "assign"]` | Which notification types to fetch. Options: `"mention"`, `"assign"`, `"comment"`, `"status_change"`. |
| `issue_types` | all types | Restrict `assigned_items` and `flagged_items` to these Jira issue types (e.g., `["Bug", "Story", "Task"]`). |

If you don't use M365, remove the `work-iq` entry and only keep the connectors you have.

---

## What the Connector Queries

During COLLECT, Dayarc will ask the Jira connector:

| Signal category | Query |
|---|---|
| `assigned_items` | "What open Jira issues are currently assigned to me?" |
| `flagged_items` | "What Jira issues have I starred or flagged as priority?" |
| `notifications` | "What new @mentions do I have in Jira since {timestamp}?" |

---

## Troubleshooting

**"Jira connector returned no results"**
- Verify `JIRA_URL`, `JIRA_EMAIL`, and `JIRA_API_TOKEN` are set correctly.
- Check that your API token has read access to the relevant Jira projects.

**"source unavailable" breadcrumbs**
- Ensure the MCP server returns issue keys (e.g., `PROJ-1234`) and URLs. Check the server's documentation for required permissions.

**Duplicate signals (Jira issue appears in both GitHub and Jira sections)**
- This is expected when a PR references a Jira ticket. `classify_activity` will group them under the same work theme.

---

## Alternatives

If `@modelcontextprotocol/server-jira` doesn't work for your setup, any MCP server that can answer the query contract described in [README.md](./README.md) will work — including self-hosted or custom implementations.

---

## Advanced: BYO Skill

If you need more control over how Jira signals are collected (e.g., custom JQL queries, multi-step API calls, or enrichment with sprint data), you can declare a custom COLLECT skill instead of using the default generic queries.

### Step 1 — Add `skill` to your connector entry

```json
{
  "name": "jira",
  "provides": ["flagged_items", "notifications", "assigned_items"],
  "skill": "jira-collect",
  "config": {
    "username": "you@example.com",
    "project_filter": ["PROJ", "INFRA"],
    "notification_reasons": ["mention", "assign"],
    "issue_types": ["Bug", "Story", "Task"]
  }
}
```

### Step 2 — Install the skill

Copy the skill definition to your skills directory:

```powershell
# Git clone install
Copy-Item -Recurse connectors/jira/skills/jira-collect ~/.copilot/skills/

# Plugin install — copy to plugin skills folder (path varies by install)
```

The skill file is at `connectors/jira/skills/jira-collect/SKILL.md` in this repo (not yet published — contribute one!).

### What the skill receives

```json
{
  "connector": "jira",
  "provides": ["flagged_items", "notifications", "assigned_items"],
  "config": { "username": "you@example.com", "project_filter": ["PROJ", "INFRA"], "notification_reasons": ["mention", "assign"], "issue_types": ["Bug", "Story", "Task"] },
  "lookback": "today",
  "since_timestamp": "2026-04-04T20:00:00Z"
}
```

### What the skill must return

An array of normalized signals matching the signal shape in [CONNECTOR-INTERFACE.md](../CONNECTOR-INTERFACE.md).
