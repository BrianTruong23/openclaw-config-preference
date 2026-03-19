---
name: spawn-coding-agent
description: Spawn a coding agent against a specific git repo using the live OpenClaw exec and process tools. Use when the user wants Codex or another coding CLI to work on a repo path, review code, or make changes in a repo on the VPS.
metadata:
  {
    "openclaw":
      {
        "emoji": "🧩",
        "requires": { "bins": ["openclaw", "codex", "codex-tmux", "tmux"] },
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
Prefer the real OpenClaw `coding-agent` first. Use Codex CLI only as a fallback when the user explicitly wants Codex CLI behavior or the OpenClaw coding-agent path is unavailable.

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

Prefer the actual OpenClaw sub-agent:

```text
exec:
  command: openclaw agent --agent coding-agent --json --timeout 1800 --message 'Work only in /path/to/repo. Treat that directory as the source of truth. First inspect the git state there, then do this task: Your task here. Before you claim success, verify any created or modified files from that exact repo path and report the verification output.'
  workdir: /path/to/repo
```

The JSON response includes a real coding-agent session id in:

```text
result.meta.agentMeta.sessionId
```

If you need to inspect the underlying OpenClaw session log:

```text
exec:
  command: sed -n '1,200p' /root/.openclaw/agents/coding-agent/sessions/<session-id>.jsonl
  workdir: /path/to/repo
```

## Shared Filesystem Verification

The coding-agent is not done just because it reported success in its own session. The host repo path must show the changes.

Required checks after any coding-agent run:

- Verify expected files directly from the host repo path with `ls -l`, `stat`, `find`, `sed`, or `git status`.
- If the task mentioned a specific file such as `requirements.txt`, `.venv`, or `src/app.py`, check that exact path from the host filesystem.
- If a file is missing from the host repo path, treat the run as not complete even if the coding-agent claimed it wrote the file.
- Report concrete verification results such as `ls -l /path/to/repo/file.py` or `git status --short`.
- If verification fails or is ambiguous, say so plainly and continue debugging instead of summarizing the coding-agent's claim as success.

Verification example:

```text
exec:
  command: sh -lc 'pwd && git status --short && ls -l requirements.txt .venv 2>/dev/null || true && find . -maxdepth 2 -type f | sed -n "1,40p"'
  workdir: /path/to/repo
```

## Secondary Pattern

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

## Last-Resort Fallback Pattern

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
- command: openclaw agent --agent coding-agent --json --timeout 1800 --message 'Work in /root/projects/my-repo. Inspect the repo, add tests for the API client, and commit the changes.'
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
- Prefer `openclaw agent --agent coding-agent` so the work lands in the real OpenClaw coding-agent session store.
- Report the real coding-agent session id from the JSON response when available.
- Never treat a coding-agent completion message as proof that files persisted to the shared workspace.
- After the agent finishes, verify the target repo path from the host before claiming files were created, modified, or runnable.
- If the task involved a virtual environment or install output, verify the directory or binary exists from the host repo path before reporting success.
- If you inspect a coding-agent session, read its `.jsonl` file and summarize the latest assistant output or error instead of guessing.
- Treat the trusted target repo as a high-autonomy workspace and only fall back to `codex exec --dangerously-bypass-approvals-and-sandbox` when you intentionally want raw Codex CLI behavior.
- Use `codex-tmux` only as a fallback observability path for Codex CLI, not as the primary "coding-agent" implementation.
- If the repo path is missing, ask for the exact path or repo URL.
