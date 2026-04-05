# Summary: Issue #17 — Localization (translate-at-delivery approach)

## Approach

Per reviewer feedback, the pipeline runs entirely in English. Translation happens in **dayarc-deliver** as the final step before sending, minimising changes across skills and prompts.

## What was changed and why

### `config.example.json`
Added top-level `"locale": "en"` field — the only config change needed. Placed at top level (not inside `preferences`) as it affects the whole experience.

### `skills/dayarc-setup/SKILL.md`
- Step 2: added a 4th identity question asking the user for their preferred language (`en` / `zh`, default `en`).
- Step 3: `locale` is now written to `config.json`.

### `agents/dayarc.agent.md`
Added a minimal **Locale** section: read `locale` from config and pass it to **dayarc-deliver**. The agent otherwise runs entirely in English.

### `prompts/pm.md`, `am.md`, `weekly.md`, `monthly.md`
Each prompt now reads `locale` from config and passes it to **dayarc-deliver**. No other changes — content generation remains in English.

### `skills/dayarc-deliver/SKILL.md`
- Added a translate step (step 2) in the Scheduled delivery mode: if `locale != "en"`, translate the rendered HTML body text into the target language before saving and sending. HTML tags, inline styles, emoji, and source breadcrumb links are preserved; only visible text is translated.
- Added locale-aware email subjects for `en` and `zh`.
- Same translate step applies for Conversational (terminal) mode.

### `skills/dayarc-deliver/templates/*.hbs`
- Added `lang="{{locale}}"` on `<html>` for correct rendering in email clients.
- Extended font stack with `'PingFang SC', 'Microsoft YaHei'` for CJK character support.
- Section headings remain hardcoded English (translation handles them at send time).

## Spec / design support

- Spec §3 Goal G5 — scannable briefs for non-English users.
- Spec §11 (Portable workspace) — `locale` in `config.json` is the single source of user preferences.
- Backward compatible: `locale` defaults to `"en"` if absent; existing configs unchanged.
