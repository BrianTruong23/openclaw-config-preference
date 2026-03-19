# OpenClaw Config Preference

This repo stores my preferred OpenClaw coding-agent baseline.

It is meant to be applied after installing OpenClaw on a VPS so the Telegram bot can reliably spawn Codex for repo work without getting stuck on the common approval and trust prompts.

## What This Applies

- Enables elevated runtime commands for my Telegram user ID.
- Switches the main tool profile to `coding`.
- Sets `tools.exec.security = "full"`.
- Sets `tools.exec.ask = "off"` for `main` and `coding-agent`.
- Sets `coding-agent` to the valid OpenClaw model `openrouter/google/gemini-2.5-flash`.
- Enables Telegram session-based exec approvals.
- Installs `gh` (GitHub CLI).
- Installs `gws` (Google Workspace CLI).
- Installs `clawhub` (ClawHub CLI).
- Installs `gws-openclaw`, a wrapper that reuses the OpenClaw Google token for `gws`.
- Materializes `~/.config/gws/credentials.json` from the OpenClaw Google token when present so native `gws` Drive calls work without extra setup.
- Installs `openclaw-skillhub`, a wrapper that targets `/root/.openclaw/skills`.
- Syncs a patched `spawn-coding-agent` skill.
- Syncs a managed `clawhub-skills` installer skill.
- Installs default ClawHub skills:
  `agent-browser-clawdbot`, `agent-daily-planner`, `agent-swarm`, `agent-team-orchestration`, `self-reflection`, `joko-moltbook`, `tweet-writer`, `us-stock-analysis`, `csv-pipeline`, `automation-workflows`, `free-ride`, `mac-tts`, `n8n`, and `clawtoclaw`
- Syncs a managed `google-workspace` skill that constrains the agent to stable `gws-openclaw` helper commands.
- Syncs the native `google-drive-docs` skill and helper script.
- Installs the `gdrive-doc` wrapper, `gws`, and Python dependencies for Google Drive, Docs, Sheets, and Slides.
- Optionally marks a repo path as trusted in `~/.codex/config.toml`.
- Makes `spawn-coding-agent` use the real `openclaw agent --agent coding-agent` path first.
- Keeps raw Codex CLI and `codex-tmux` as fallback paths when explicitly needed.
- Restarts `openclaw-gateway`.

## Files

- `scripts/bootstrap_openclaw_coding_mode.sh`
- `scripts/gdrive_doc_remote.py`
- `scripts/gws_openclaw.sh`
- `scripts/openclaw_skillhub.sh`
- `templates/clawhub-skills.SKILL.md`
- `templates/clawhub-skills.openai.yaml`
- `templates/google-drive-docs.SKILL.md`
- `templates/google-drive-docs.openai.yaml`
- `templates/google-workspace.SKILL.md`
- `templates/google-workspace.openai.yaml`
- `templates/openclaw-workspace-AGENTS.md`
- `templates/spawn-coding-agent.SKILL.md`

## Usage

Run from a local machine that can SSH to the VPS:

```bash
./scripts/bootstrap_openclaw_coding_mode.sh root@76.13.24.24 7810829778 /root/.openclaw/workspace/centralized_dashboard
```

Generic usage:

```bash
./scripts/bootstrap_openclaw_coding_mode.sh [root@host] [telegram_sender_id] [/optional/repo/path]
```

## Resulting Behavior

After bootstrapping, OpenClaw should:

- use the patched `spawn-coding-agent` skill
- route coding work into the real OpenClaw `coding-agent` session store
- stop asking for OpenClaw exec approval in the main coding workflow
- allow the main OpenClaw agent to create and modify files more freely
- be allowed to run elevated commands from Telegram for the configured sender
- route approval-gated exec prompts back into the Telegram session
- avoid Codex's interactive repo trust prompt for repos that were pre-trusted
- run the OpenClaw `coding-agent` on the valid model `openrouter/google/gemini-2.5-flash`
- keep raw Codex CLI available as a fallback for trusted repos
- have `gh` installed and available for GitHub issue/PR workflows
- have the native `google-drive-docs` skill available through `gdrive-doc`
- have `gws` available for lower-level Google Workspace API calls
- have `gws-openclaw` available so `gws` can reuse the OpenClaw Google auth state
- have native `gws` Drive calls work through `/root/.config/gws/credentials.json` synthesized from the OpenClaw token when available
- have a managed `google-workspace` skill that uses only stable `gws-openclaw` helper commands
- have `clawhub` and `openclaw-skillhub` available for skill search/install/update
- have a managed `clawhub-skills` skill inside OpenClaw
- have `agent-browser-clawdbot`, `agent-daily-planner`, `agent-swarm`, `agent-team-orchestration`, `self-reflection`, `joko-moltbook`, `tweet-writer`, `us-stock-analysis`, `csv-pipeline`, `automation-workflows`, `free-ride`, `mac-tts`, `n8n`, and `clawtoclaw` installed by default
- have workspace-level "verify before reporting" guardrails to reduce hallucinated success claims
- be able to create Google Docs, Sheets, Slides, and Drive uploads when `/root/.config/openclaw/google-drive/client_secrets.json` and `token.json` are present

## Notes

- This baseline intentionally gives Codex maximum autonomy in trusted repos. Use it only on repos and VPSes you are comfortable letting the agent modify freely.
- The bootstrap script is intentionally narrow. It targets my sender ID and does not open elevated access broadly.
- `gh` will work through the `GITHUB_TOKEN` loaded from `/root/.config/openclaw/openclaw.env`; this avoids requiring interactive `gh auth login` in the normal OpenClaw service flow.
- Google Drive OAuth client secrets should live at `/root/.config/openclaw/google-drive/client_secrets.json`.
- Google Drive access tokens should live at `/root/.config/openclaw/google-drive/token.json`.
- Gmail and Calendar still require a broader native `gws auth login` if the OpenClaw token was not authorized with those scopes.
- `mac-tts` is macOS-specific; it can be installed in the baseline but will not function on a Linux VPS.
