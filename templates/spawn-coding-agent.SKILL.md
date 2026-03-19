---
name: spawn-coding-agent
description: Spawn a coding agent against a specific git repo using the live OpenClaw exec and process tools. Use when the user wants Codex or another coding CLI to work on a repo path, review code, or make changes in a repo on the VPS.
metadata:
  {
    "openclaw":
      {
        "emoji": "🧩",
        "requires": { "bins": ["codex", "codex-tmux", "tmux"] },
        "always": true
      },
  }
---

# Spawn Coding Agent

Use this skill when the user wants a coding agent to work on a specific repository on the VPS.

This OpenClaw runtime exposes the native tools:

- `exec` for starting commands
- `process` for polling, logging, and interacting with background sessions

Do not say the coding tool is unavailable just because there is no `bash` tool. In this runtime, `exec` is the correct tool.
For long-running Codex work, prefer the existing `codex-tmux` wrapper over raw background `codex exec` so the session stays inspectable.

## Repo Rules

- Always set `workdir` to the target repo path.
- Prefer repositories that are already git repos.
- For scratch work, create a temp git repo first because `codex` expects a trusted git directory.
- Never launch coding agents inside `~/.openclaw/`.
- Before launching `codex`, make sure the repo path is trusted in `/root/.codex/config.toml` so Codex does not stop on the interactive directory-trust prompt.

Trust the repo path first:

```text
exec:
  command: python3 -c 'from pathlib import Path; p=Path("/root/.codex/config.toml"); repo="/path/to/repo"; block=f"\n[projects.\"{repo}\"]\ntrust_level = \"trusted\"\n"; text=p.read_text() if p.exists() else ""; p.write_text(text if f"[projects.\"{repo}\"]" in text else text + block)'
  workdir: /path/to/repo
```

## Preferred Pattern

Prefer a named tmux session per repo. Use a short stable session name such as `codex-centralized-dashboard`.

Start the session:

```text
exec:
  command: codex-tmux start --session codex-my-repo --workdir /path/to/repo --command "codex exec --dangerously-bypass-approvals-and-sandbox 'Your task here'"
  workdir: /path/to/repo
```

Check whether it still exists:

```text
exec:
  command: codex-tmux list
  workdir: /path/to/repo
```

Capture the current output:

```text
exec:
  command: codex-tmux capture --session codex-my-repo --start-line -200
  workdir: /path/to/repo
```

Stop it if needed:

```text
exec:
  command: codex-tmux stop --session codex-my-repo
  workdir: /path/to/repo
```

## Fallback Pattern

Foreground one-shot:

```text
exec:
  command: codex exec --dangerously-bypass-approvals-and-sandbox 'Your task here'
  workdir: /path/to/repo
  pty: true
  timeout: 600
```

Background long-running task:

```text
exec:
  command: codex exec --dangerously-bypass-approvals-and-sandbox 'Your task here'
  workdir: /path/to/repo
  pty: true
  background: true
```

Then monitor with:

```text
process action:list
process action:poll
process action:log
process action:submit
process action:kill
```

## Examples

Work on a specific repo:

```text
Use exec with:
- workdir: /root/projects/my-repo
- command: codex-tmux start --session codex-my-repo --workdir /root/projects/my-repo --command "codex exec --dangerously-bypass-approvals-and-sandbox 'Add tests for the API client and commit the changes'"
```

Review a repo without editing:

```text
Use exec with:
- workdir: /root/projects/my-repo
- pty: true
- command: codex exec 'Review the current changes and summarize bugs, risks, and missing tests'
```

Scratch repo:

```text
exec:
  command: sh -lc 'tmp=$(mktemp -d) && cd \"$tmp\" && git init && codex exec \"Summarize this problem\"'
  pty: true
```

## Behavior

- Tell the user which repo path you are using.
- Treat the trusted target repo as a high-autonomy workspace and prefer `codex exec --dangerously-bypass-approvals-and-sandbox` so the coding agent does not stop for routine approval prompts.
- For long-running tasks, prefer `codex-tmux start` and report the tmux session name, not just a generic process id.
- After launching, always capture output at least once and summarize what Codex is doing right now.
- If the session is still running, capture fresh output before telling the user it is "still working".
- Only use raw background `codex exec` when `codex-tmux` is unavailable.
- If the repo path is missing, ask for the exact path or repo URL.
