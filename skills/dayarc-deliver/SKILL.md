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
- PM `en`: `🌙 Evening Wrap-up — {date}` · `zh`: `🌙 今日总结 — {date}`
- AM `en`: `☀️ Morning Brief — {date}` · `zh`: `☀️ 早间简报 — {date}`
- Weekly `en`: `📊 Weekly — Week of {date}` · `zh`: `📊 本周回顾 — {date}当周`
- Monthly `en`: `📅 Monthly — {month} {year}` · `zh`: `📅 本月报告 — {year}年{month}月`

## Template Data

When rendering any template, the caller must pass:
- `locale` — the user's locale code (e.g., `"en"`, `"zh"`). Defaults to `"en"` if absent.
- Localized section heading strings for the template's `h_*` variables (see each template's variable list below). The calling prompt is responsible for providing locale-appropriate text for these headings.

### Section heading variables by template

**pm.hbs** — `h_what_i_did`, `h_priorities`, `h_unfinished`

| Variable | `en` default | `zh` default |
|---|---|---|
| `h_what_i_did` | 📋 What I Did Today | 📋 今日工作 |
| `h_priorities` | 🎯 My Priorities Today | 🎯 今日优先事项 |
| `h_unfinished` | ⏳ Left Unfinished | ⏳ 未完成事项 |

**am.hbs** — `h_todays_plan`, `h_learning`, `h_signals`, `h_may_forget`

| Variable | `en` default | `zh` default |
|---|---|---|
| `h_todays_plan` | 📋 Today's Plan | 📋 今日计划 |
| `h_learning` | 📚 Recommended Learning | 📚 推荐学习 |
| `h_signals` | 📨 Incoming Signals | 📨 重要信号 |
| `h_may_forget` | ⚠️ You May Forget | ⚠️ 注意勿忘 |

**weekly.hbs** — `h_themes`, `h_accomplishments`, `h_stuck`, `h_next_week`

| Variable | `en` default | `zh` default |
|---|---|---|
| `h_themes` | 🎯 This Week's Themes | 🎯 本周主题 |
| `h_accomplishments` | ✅ Accomplishments | ✅ 本周成果 |
| `h_stuck` | 🔄 Stuck / Recurring Carryovers | 🔄 滞留/反复遗留 |
| `h_next_week` | 🔮 Next Week's Suggested Focus | 🔮 下周建议重点 |

**monthly.hbs** — `h_time_allocation`, `h_accomplishments`, `h_stuck`, `h_learning`, `h_next_month`

| Variable | `en` default | `zh` default |
|---|---|---|
| `h_time_allocation` | 📊 Where My Time Went | 📊 时间分配 |
| `h_accomplishments` | ✅ Key Accomplishments | ✅ 重要成果 |
| `h_stuck` | 🚫 Persistently Stuck | 🚫 长期未解决 |
| `h_learning` | 📚 Learning Progress | 📚 学习进展 |
| `h_next_month` | 🔮 Next Month's Outlook | 🔮 下月展望 |
Render the brief as formatted text in the terminal. Do NOT send email unless the user explicitly says "send it".

## Instructions
1. Verify Outlook is running before attempting send (check process).
2. If Outlook not available, display in terminal and note that email was not sent.
3. Clean up temp files after sending.
