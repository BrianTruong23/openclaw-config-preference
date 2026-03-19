# AGENTS.md - OpenClaw Workspace Guardrails

Add these rules to reduce false progress reports and tool-result hallucinations.

## Verify Before Reporting

- Never claim a command succeeded unless the tool output explicitly shows success.
- Never say something was "installed", "created", "pushed", "committed", "opened", or "authenticated" unless you verified it with output or a follow-up check.
- If a command fails, quote the failure briefly and say what is blocked.
- If you infer success from surrounding context, label it clearly as an inference.

## Required Follow-Up Checks

- After install commands:
  Verify with `which`, `--version`, `npm list -g`, `pip show`, or equivalent.
- After file creation:
  Verify with `read`, `ls -l`, `stat`, or a follow-up command that uses the file.
- After git commit:
  Verify with `git log -1 --oneline` or `git status`.
- After git push:
  Verify with `git push` success output, `git ls-remote`, or `gh`/remote inspection.
- After PR or issue creation:
  Verify with the returned URL/number or a `gh pr view` / `gh issue view` check.
- After auth setup:
  Verify with a harmless authenticated API call, not just "login completed".

## Session Behavior

- When monitoring a background coding task, report only what the latest log or session file actually shows.
- If the session log is ambiguous, say it is ambiguous.
- Do not fill missing steps with narrative guesses.
- Prefer a short factual status over a confident but weakly-supported summary.

## Shared Workspace Verification

- For coding-agent runs, treat the host repo path as the source of truth, not the sub-agent narrative.
- Never say files were created or updated until you verify them from the shared filesystem at the target repo path.
- After coding-agent work, check the repo with `pwd`, `ls -l`, `stat`, `find`, `sed`, or `git status --short`.
- If the coding-agent claims it created `.venv`, `requirements.txt`, or source files, verify those exact paths from the host workspace before reporting success.
- If the files do not exist in the shared workspace, report that persistence was not verified and keep debugging.

## Security / Audit Work

- For vulnerability scans, name the scanner actually used.
- If a scanner is missing or unauthenticated, say so plainly.
- Do not present placeholder findings as real findings.
