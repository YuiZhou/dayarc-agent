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

Email subjects (translate the subject too if `locale` is not `en`):
- PM: `🌙 Evening Wrap-up — {date}`
- AM: `☀️ Morning Brief — {date}`
- Weekly: `📊 Weekly — Week of {date}`
- Monthly: `📅 Monthly — {month} {year}`

### Conversational (terminal)
Render the brief as formatted text in the terminal. If `locale` is not `en`, translate the output before displaying. Do NOT send email unless the user explicitly says "send it".

## Instructions
1. Verify Outlook is running before attempting send (check process).
2. If Outlook not available, display in terminal and note that email was not sent.
3. **Idempotency check — run before every scheduled send:**
   Query Outlook Sent Items for a message with today's brief subject (e.g. `🌙 Evening Wrap-up — {date}`). Use the Outlook COM object:
   ```powershell
   $ol = New-Object -ComObject Outlook.Application
   $sent = $ol.Session.GetDefaultFolder(5)  # 5 = olFolderSentMail
   $subject = "{subject}"
   $alreadySent = $sent.Items | Where-Object { $_.Subject -eq $subject } | Select-Object -First 1
   if ($alreadySent) {
       Write-Host "already delivered — skipping send (ItemID: $($alreadySent.EntryID))"
       exit 0
   }
   ```
   If a matching item is found, log `already delivered` and skip sending. Do not send a second copy.
4. Clean up temp files after sending.
