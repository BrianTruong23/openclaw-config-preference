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
- Syncs a patched `spawn-coding-agent` skill.
- Optionally marks a repo path as trusted in `~/.codex/config.toml`.
- Makes `spawn-coding-agent` use the real `openclaw agent --agent coding-agent` path first.
- Keeps raw Codex CLI and `codex-tmux` as fallback paths when explicitly needed.
- Restarts `openclaw-gateway`.

## Files

- `scripts/bootstrap_openclaw_coding_mode.sh`
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

## Notes

- This baseline intentionally gives Codex maximum autonomy in trusted repos. Use it only on repos and VPSes you are comfortable letting the agent modify freely.
- The bootstrap script is intentionally narrow. It targets my sender ID and does not open elevated access broadly.
- `gh` will work through the `GITHUB_TOKEN` loaded from `/root/.config/openclaw/openclaw.env`; this avoids requiring interactive `gh auth login` in the normal OpenClaw service flow.
