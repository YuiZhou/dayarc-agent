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
2. **If `locale` is not `en`:** Translate the rendered HTML body text into the target language before sending. Preserve all HTML tags, inline styles, emoji, and source breadcrumb links unchanged — translate only the visible text content.
3. Save rendered (and translated, if applicable) HTML to a temp file.
4. Send via Outlook COM:
```powershell
$ol = New-Object -ComObject Outlook.Application
$mail = $ol.CreateItem(0)
$mail.To = $ol.Session.CurrentUser.Address
$mail.Subject = "{subject}"
$mail.HTMLBody = Get-Content "{html-path}" -Raw
$mail.Send()
```

Email subjects:
- PM `en`: `🌙 Evening Wrap-up — {date}` · `zh`: `🌙 今日总结 — {date}`
- AM `en`: `☀️ Morning Brief — {date}` · `zh`: `☀️ 早间简报 — {date}`
- Weekly `en`: `📊 Weekly — Week of {date}` · `zh`: `📊 本周回顾 — {date}当周`
- Monthly `en`: `📅 Monthly — {month} {year}` · `zh`: `📅 本月报告 — {year}年{month}月`

### Conversational (terminal)
Render the brief as formatted text in the terminal. If `locale` is not `en`, translate the output before displaying. Do NOT send email unless the user explicitly says "send it".

## Instructions
1. Verify Outlook is running before attempting send (check process).
2. If Outlook not available, display in terminal and note that email was not sent.
3. Clean up temp files after sending.
