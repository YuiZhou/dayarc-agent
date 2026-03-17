---
name: Deliver Brief
description: Render HTML brief from template and send via Outlook or display in terminal.
---

## Templates
Located in this skill's `templates/` directory:
- `pm.hbs` — Evening Wrap-up
- `am.hbs` — Morning Brief
- `weekly.hbs` — Weekly Report
- `monthly.hbs` — Monthly Report

## Delivery Modes

### Scheduled (send email)
1. Render the appropriate .hbs template with brief data.
2. Save rendered HTML to a temp file.
3. Send via Outlook COM:
```powershell
$ol = New-Object -ComObject Outlook.Application
$mail = $ol.CreateItem(0)
$mail.To = $ol.Session.CurrentUser.Address
$mail.Subject = "{subject}"
$mail.HTMLBody = Get-Content "{html-path}" -Raw
$mail.Send()
```

Email subjects:
- PM: `🌙 Evening Wrap-up — {date}`
- AM: `☀️ Morning Brief — {date}`
- Weekly: `📊 Weekly — Week of {date}`
- Monthly: `📅 Monthly — {month} {year}`

### Conversational (terminal)
Render the brief as formatted text in the terminal. Do NOT send email unless the user explicitly says "send it".

## Instructions
1. Verify Outlook is running before attempting send (check process).
2. If Outlook not available, display in terminal and note that email was not sent.
3. Clean up temp files after sending.
