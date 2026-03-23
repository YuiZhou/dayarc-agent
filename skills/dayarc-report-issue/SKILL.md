---
name: Dayarc Report Issue
description: Auto-fill and file a GitHub issue on the Dayarc repo with user confirmation.
---

## When to Use

User asks to report a bug, file an issue, or request a feature for Dayarc.

## Behavior

1. **Classify** — Determine if this is a `bug` or `enhancement` from conversation context.
2. **Collect** — Gather:
   - Skill name involved (if applicable)
   - What happened vs what was expected
   - Brief type (AM/PM/Weekly/Monthly) if relevant
   - Version: run `git describe --tags --always` in `~/.dayarc-agent/`
   - Platform: `$env:OS` + PowerShell version
3. **Sanitize** — Strip all PII before composing the issue body (see rules below).
4. **Preview** — Show the full issue title and body in the terminal. User can edit or cancel.
5. **Confirm** — Wait for explicit "yes" before filing. Never file without confirmation.
6. **File** — Run:
   ```
   gh issue create --repo YuiZhou/dayarc-agent --title "{title}" --body "{body}" --label "{bug|enhancement}"
   ```
7. **Report** — Show the issue URL to the user.

## Issue Body Format

### Bug Report
```markdown
## Bug Report (auto-filed by Dayarc)
**What happened:** [one sentence]
**Expected:** [one sentence]
**Skill:** [name] | **Brief type:** [AM/PM/Weekly/Monthly]
**Version:** [version] | **Platform:** [OS]
### Reproduction context
[Sanitized description of what led to the issue]
### Suggested area
[Likely file(s) or skill(s) involved]
```

### Feature Request
```markdown
## Feature Request (auto-filed by Dayarc)
**What:** [one sentence]
**Why:** [motivation]
**Related brief/skill:** [if applicable]
```

## PII Sanitization Rules

| ✅ Include | ❌ Exclude |
|-----------|-----------|
| Skill names, version, platform, dates | Email content, subjects, senders |
| Theme labels ("flagged emails") | Contact names, memory contents, config values |
| Error description, likely file paths | Repo names, PR titles from user's work |

## Safety

- **Dayarc repo only.** The target repo `YuiZhou/dayarc-agent` is hardcoded. Never file issues on any other repository. If the user asks to file an issue elsewhere, refuse.
- **User confirms.** Never file without explicit "yes" after preview.
- **No PII.** Apply sanitization rules strictly. When in doubt, omit.
