# Azure DevOps (ADO) Connector

This is a community connector that replaces or supplements the GitHub connector for teams that use **Azure DevOps** for repositories, pipelines, and work items.

| Field | Value |
|---|---|
| Signal types | `outgoing_messages`, `assigned_work`, `incoming_signals` |
| MCP package | [`@azure-devops/mcp`](https://github.com/microsoft/azure-devops-mcp) |
| Auth | Azure CLI (`az login`) or PAT via `AZURE_DEVOPS_PAT` env var |

---

## Prerequisites

1. Install the Azure DevOps MCP server:
   ```powershell
   npm install -g @azure-devops/mcp
   ```

2. Authenticate:
   ```powershell
   az login
   # OR set a Personal Access Token (Scopes: Code read, Work Items read):
   $env:AZURE_DEVOPS_PAT = "your-pat-here"
   ```

3. Note your ADO organization URL (e.g. `https://dev.azure.com/my-org`).

---

## Setup

### Step 1 — Declare the MCP server in your agent profile

Open `~/.copilot/agents/dayarc.agent.md` (plugin install) or `~/.dayarc-agent/agents/dayarc.agent.md` (git clone) and add the `ado` server to the `mcp-servers` frontmatter block:

```yaml
---
name: Dayarc
description: Collects signals from M365 and GitHub, learns your work patterns, and delivers personalized briefs.
mcp-servers:
  work-iq:
    type: stdio
    command: npx
    args: ["-y", "@microsoft/workiq", "mcp"]
    tools: ["*"]
  github:
    type: stdio
    command: npx
    args: ["-y", "@modelcontextprotocol/server-github"]
    tools: ["*"]
  ado:
    type: stdio
    command: npx
    args: ["-y", "@azure-devops/mcp"]
    env:
      AZURE_DEVOPS_ORG_URL: "https://dev.azure.com/my-org"
    tools: ["*"]
---
```

Replace `https://dev.azure.com/my-org` with your organization URL.

### Step 2 — Declare the connector in config.json

Open `~/Documents/dayarc/config.json` and add an `ado` entry to the `connectors` array. Keep or remove `github` depending on whether you still use GitHub alongside ADO.

**ADO only (no GitHub):**
```json
{
  "connectors": [
    {
      "name": "work-iq",
      "label": "M365 (Outlook + Teams + SharePoint)",
      "provides": ["outgoing_messages", "flagged_items", "calendar", "documents", "incoming_signals"]
    },
    {
      "name": "ado",
      "label": "Azure DevOps",
      "provides": ["outgoing_messages", "assigned_work", "incoming_signals"]
    }
  ]
}
```

**ADO + GitHub side by side:**
```json
{
  "connectors": [
    {
      "name": "work-iq",
      "label": "M365 (Outlook + Teams + SharePoint)",
      "provides": ["outgoing_messages", "flagged_items", "calendar", "documents", "incoming_signals"]
    },
    {
      "name": "github",
      "label": "GitHub",
      "provides": ["outgoing_messages", "assigned_work", "incoming_signals"]
    },
    {
      "name": "ado",
      "label": "Azure DevOps",
      "provides": ["outgoing_messages", "assigned_work", "incoming_signals"]
    }
  ]
}
```

---

## Signal Mapping

| Signal type | What the ADO MCP server returns |
|---|---|
| `outgoing_messages` | Commits authored, PRs created, work item updates authored |
| `assigned_work` | Work items assigned to you, PRs awaiting your review |
| `incoming_signals` | @mentions in PRs/work items, newly assigned items |

---

## Notes

- The ADO connector covers the same signal types as the GitHub connector. If your team uses both ADO and GitHub, include both in `connectors` — Dayarc will merge signals from both sources.
- Calendar, flagged items, and documents are provided by the M365 (Work IQ) connector, not ADO. Keep `work-iq` in your connectors list for those.
- Work item fields (`assigned to`, `state`, `area path`) are mapped to Dayarc's signal types on a best-effort basis. If the ADO MCP server exposes additional tools, the agent will use them automatically.
- If `AZURE_DEVOPS_PAT` is not set and `az login` is not active, the ADO MCP server will fail at startup. Dayarc will note the gap in the brief and continue with other connectors.
