---
name: clawhub-skills
description: Search, inspect, install, update, and list OpenClaw skills from ClawHub into /root/.openclaw/skills.
metadata:
  {
    "openclaw":
      {
        "emoji": "🧰",
        "requires": { "bins": ["clawhub", "openclaw-skillhub"] },
        "always": true
      },
  }
---

# ClawHub Skills

Use this skill when the user wants to search for, inspect, install, update, or list OpenClaw skills from ClawHub.

This setup uses:

- `clawhub` as the registry CLI
- `openclaw-skillhub` as the local wrapper that always targets `/root/.openclaw/skills`

## Commands

Search for public skills:

```bash
openclaw-skillhub search weather
```

Inspect a skill before installing:

```bash
openclaw-skillhub inspect weather
```

Install a skill:

```bash
openclaw-skillhub install weather --no-input
```

List installed ClawHub skills:

```bash
openclaw-skillhub list
```

Update one skill:

```bash
openclaw-skillhub update weather --no-input
```

Update all installed ClawHub skills:

```bash
openclaw-skillhub update --no-input
```

Uninstall a skill:

```bash
openclaw-skillhub uninstall weather --no-input
```

## Behavior

- Prefer `inspect` before `install` if the skill is unfamiliar.
- After install or update, verify the skill exists under `/root/.openclaw/skills/<slug>`.
- After install or update, restart the gateway if immediate pickup matters:

```bash
systemctl --user restart openclaw-gateway
```

- Report the actual installed skill slug and the path on disk.
- Do not claim install success unless `clawhub` exits successfully and the target skill folder exists.

## Safety

- Public skills are third-party code and instructions. Treat them as untrusted until inspected.
- Prefer well-maintained skills with clear summaries and owners.
- If a skill would overwrite an existing manually managed skill, stop and tell the user.
