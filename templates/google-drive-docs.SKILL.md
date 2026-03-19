---
name: google-drive-docs
description: Use Google Drive and Google Workspace files from OpenClaw. Create Docs, Sheets, Slides, upload local files, and default to /My Drive/spring_2026/OpenClaw unless the user names another folder.
homepage: https://developers.google.com/drive/api/guides/about-sdk
metadata:
  {
    "openclaw":
      {
        "emoji": "📄",
        "requires": { "bins": ["gdrive-doc", "gws", "gws-openclaw"] },
        "always": true
      },
  }
---

# Google Drive Docs

Use this skill whenever the user asks to create, upload, or organize files in Google Drive or Google Workspace.

Prefer `gdrive-doc` for the common high-level actions in this skill.
Use `gws-openclaw` when you need a lower-level Google Workspace API operation that `gdrive-doc` does not cover, because it reuses the OpenClaw Google token.

Default behavior:

- If the user does not name a folder, use `/My Drive/spring_2026/OpenClaw`.
- If the user asks for a Google Doc, run `create-doc`.
- If the user asks for a Google Sheet, run `create-sheet`.
- If the user asks for a Google Slides deck or presentation, run `create-slides`.
- If the user asks to upload a file from disk, run `upload-file`.

Before creating or uploading files, you may run this readiness check:

```bash
gdrive-doc status --resolve-default-folder
```

The default target folder in this setup is:

```bash
/My Drive/spring_2026/OpenClaw
```

## Commands

Authorize Google Drive access:

```bash
gdrive-doc auth --port 8091
```

Ensure a folder path exists:

```bash
gdrive-doc ensure-folder --folder-path "/My Drive/spring_2026/OpenClaw"
```

Or just:

```bash
gdrive-doc ensure-folder
```

Create a Google Doc:

```bash
gdrive-doc create-doc \
  --folder-path "/My Drive/spring_2026/OpenClaw" \
  --title "Meeting Notes" \
  --content "Hello from OpenClaw"
```

Or omit the folder:

```bash
gdrive-doc create-doc --title "Meeting Notes" --content "Hello from OpenClaw"
```

Create a Google Sheet:

```bash
gdrive-doc create-sheet \
  --folder-path "/My Drive/spring_2026/OpenClaw" \
  --title "Budget Draft" \
  --range-name "A1:B2" \
  --values-json '[["Item","Value"],["Example",123]]'
```

Or omit the folder:

```bash
gdrive-doc create-sheet --title "Budget Draft" --range-name "A1:B2" --values-json '[["Item","Value"],["Example",123]]'
```

Create a Google Slides deck:

```bash
gdrive-doc create-slides \
  --folder-path "/My Drive/spring_2026/OpenClaw" \
  --title "Project Update" \
  --text "OpenClaw slide title\nSubtitle text"
```

Or omit the folder:

```bash
gdrive-doc create-slides --title "Project Update" --text "OpenClaw slide title\nSubtitle text"
```

Upload a local file:

```bash
gdrive-doc upload-file \
  --folder-path "/My Drive/spring_2026/OpenClaw" \
  --file-path /path/to/local/file.pdf
```

Or omit the folder:

```bash
gdrive-doc upload-file --file-path /path/to/local/file.pdf
```

Lower-level Drive API example through the OpenClaw token wrapper:

```bash
gws-openclaw drive files list --params '{"pageSize":1}'
```

## Argument Mapping

Map user requests to command arguments like this:

- Doc title -> `--title`
- Doc body text -> `--content`
- Sheet title -> `--title`
- Sheet cells/table data -> `--values-json`
- Sheet target range -> `--range-name` if the user specifies it, otherwise keep the default
- Slides title -> `--title`
- Slides text or slide body -> `--text`
- Local file path to upload -> `--file-path`
- Target Google Drive folder -> `--folder-path` only when the user explicitly overrides the default folder

## Telegram Prompting

Examples to send the bot:

- `Use the google-drive-docs skill to create a Google Doc in /My Drive/spring_2026/OpenClaw titled "Meeting Notes" with content "hello world".`
- `Use the google-drive-docs skill to create a Google Doc titled "Meeting Notes" with content "hello world". Use the default Google Drive folder.`
- `Use the google-drive-docs skill to create a Google Sheet in /My Drive/spring_2026/OpenClaw titled "Budget Draft" with cells A1:B2 set to [["Item","Value"],["Rent",1200]].`
- `Use the google-drive-docs skill to create a Google Sheet titled "Budget Draft" with cells A1:B2 set to [["Item","Value"],["Rent",1200]] in the default folder.`
- `Use the google-drive-docs skill to create a Google Slides presentation in /My Drive/spring_2026/OpenClaw titled "Project Update" with slide text "Status update".`
- `Use the google-drive-docs skill to create a Google Slides presentation titled "Project Update" with slide text "Status update" in the default folder.`
- `Use the google-drive-docs skill to upload /root/report.pdf to /My Drive/spring_2026/OpenClaw.`
- `Use the google-drive-docs skill to upload /root/report.pdf to the default Google Drive folder.`
- `Use the google-drive-docs skill to check whether Google Drive access is ready, then create a Google Doc titled "Weekly Notes".`

## Notes

- OAuth client secrets live at `/root/.config/openclaw/google-drive/client_secrets.json`.
- Access tokens are stored at `/root/.config/openclaw/google-drive/token.json` after authorization.
- The helper creates missing folders under `/My Drive/...` automatically.
- `gws-openclaw` refreshes and reuses the OpenClaw Google token before calling `gws`.
