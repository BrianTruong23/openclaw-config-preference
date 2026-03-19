---
name: google-workspace
description: Google Workspace operations for Gmail, Calendar, Drive, Contacts, Sheets, and Docs through stable gws-openclaw helper commands.
---

# google-workspace

Use `gws-openclaw` for Google Workspace tasks.

Do not use:
- `gog`
- `gogcli`
- `brew`
- ad-hoc Python SMTP scripts
- `gws schema ...`
- `gws-openclaw schema ...`
- `gws calendar events list`
- `gws-openclaw calendar events list`
- any raw schema-introspection or low-level calendar listing command

This environment is already wired so `gws-openclaw` can use native `gws` credentials from `/root/.config/gws` and, if needed, fall back to the OpenClaw Drive token.

Do not claim success unless the command output confirms it.

Setup checks
- Verify the wrapper exists: `which gws-openclaw`
- Verify auth works before acting:
  - `gws-openclaw gmail +triage --format table`
  - `gws-openclaw calendar +agenda --format table`

Stable commands
- Inbox summary: `gws-openclaw gmail +triage --format table`
- Read message: `gws-openclaw gmail +read --id <messageId>`
- Send email: `gws-openclaw gmail +send --to <email> --subject "<subject>" --body "<body>"`
- Upcoming events: `gws-openclaw calendar +agenda --format table`
- Create event: `gws-openclaw calendar +insert --summary "<title>" --start "<RFC3339>" --end "<RFC3339>"`
- Create event with Meet: `gws-openclaw calendar +insert --summary "<title>" --start "<RFC3339>" --end "<RFC3339>" --meet`
- Drive list: `gws-openclaw drive files list --params '{"pageSize":10}'`

Rules
- For "list my next calendar events", use exactly `gws-openclaw calendar +agenda --format table`.
- For "send an email", use exactly `gws-openclaw gmail +send ...`.
- For "read my inbox", use exactly `gws-openclaw gmail +triage --format table`.
- Prefer the helper commands `+send`, `+triage`, `+read`, `+agenda`, and `+insert` over lower-level raw API commands.
- Confirm before sending email or creating calendar events unless the user explicitly asked for that exact action.
- Convert relative times like "tomorrow at 3pm" into exact RFC3339 timestamps before calling `calendar +insert`.
- Do not inspect command schemas or ask `gws` for function metadata unless the user explicitly asks about the CLI itself.
- If auth fails, report that `gws-openclaw` auth is unavailable. Do not switch to unrelated tools or invent a different installation path.
