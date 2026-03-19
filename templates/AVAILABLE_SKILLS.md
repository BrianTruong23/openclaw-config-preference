# AVAILABLE_SKILLS.md

Use this file as the workspace-visible index of important custom or corrected skills.

## Spawn Coding Agent

Use spawn-coding-agent when the user wants Codex to work on a specific repository path on the VPS.

Important runtime note:
- In this OpenClaw setup, the live tools are exec and process.
- Do not look for a bash tool.
- Start coding runs with exec.
- Monitor them with process.

Correct pattern:
- exec with workdir set to the repo path
- pty: true for Codex
- background: true for long-running tasks
- process to poll, log, submit input, or kill the run

Example intent:
- Use the spawn-coding-agent skill to run Codex on /path/to/repo and fix the tests.

## Google Drive Docs

Use google-drive-docs for Google Docs, Sheets, Slides, and Drive uploads.
Default folder: /My Drive/spring_2026/OpenClaw

## Reforce Session

Use reforce-session to clear the cached Telegram DM session so the next message rebuilds available_skills.

## Mastodon Client

Use mastodon-client for Mastodon search, public timeline reads, and posting statuses.

Important runtime note:
- Invoke the installed skill name `mastodon-client`.
- Do not look for repo template paths like `openclaw-config-preference/templates/mastodon-client.SKILL.md` at runtime.
- The installed skill path on the VPS is `/root/.openclaw/skills/mastodon-client/SKILL.md`.
