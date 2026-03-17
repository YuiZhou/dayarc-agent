# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |

## Reporting a Vulnerability

Please report security vulnerabilities by opening a GitHub issue with the `security` label, or email [placeholder — will be updated before release].

## Security Considerations

This system has security-sensitive capabilities:

- **Reads M365 data** — email, Teams messages, and calendar events via the Work IQ MCP server
- **Reads GitHub data** — pull requests, issues, and notifications via the GitHub MCP server
- **Sends email** — delivers briefs via Outlook COM automation
- **Writes local files** — persists memory profiles and run logs to `~/Documents/dayarc/`

Users should review their `config.json` and ensure credentials are not committed to source control.
