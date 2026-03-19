---
name: gog
description: Google Workspace operations for Gmail, Calendar, Drive, Contacts, Sheets, and Docs via gws-openclaw.
---

# gog

Use `gws-openclaw`, not `gog`, `gogcli`, `brew`, or ad-hoc Python SMTP scripts.

This environment is already wired so `gws-openclaw` reuses the OpenClaw Google auth state from:
- `/root/.config/openclaw/google-drive/token.json`

Do not claim a Google Workspace action succeeded unless the command output confirms it.

Setup checks
- Verify the wrapper exists: `which gws-openclaw`
- Verify auth works before acting: `gws-openclaw gmail +triage --format table` or `gws-openclaw calendar +agenda --format table`

Common commands
- Inbox summary: `gws-openclaw gmail +triage --format table`
- Read message: `gws-openclaw gmail +read --id <messageId>`
- Send email: `gws-openclaw gmail +send --to <email> --subject "<subject>" --body "<body>"`
- Upcoming events: `gws-openclaw calendar +agenda --format table`
- Create event: `gws-openclaw calendar +insert --summary "<title>" --start "<RFC3339>" --end "<RFC3339>"`
- Create event with Meet: `gws-openclaw calendar +insert --summary "<title>" --start "<RFC3339>" --end "<RFC3339>" --meet`
- Drive list: `gws-openclaw drive files list --params '{"pageSize":10}'`

Rules
- Confirm before sending email or creating calendar events unless the user explicitly asked for that exact action.
- For relative dates like "tomorrow at 3pm", convert to an exact RFC3339 timestamp before calling `calendar +insert`.
- Prefer the `+send`, `+triage`, `+read`, `+agenda`, and `+insert` helpers over lower-level raw API commands.
- If auth fails, report that `gws-openclaw` auth is unavailable. Do not switch to unrelated tools or invent a different installation path.
- Do not tell the user to install Homebrew for this skill on the VPS. This setup is Linux-based and already uses `gws-openclaw`.
