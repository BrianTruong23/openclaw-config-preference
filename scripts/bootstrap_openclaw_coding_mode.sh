#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-root@76.13.24.24}"
SENDER_ID="${2:-7810829778}"
REPO_PATH="${3:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_SRC="${ROOT_DIR}/templates/spawn-coding-agent.SKILL.md"
SKILL_DST="/root/.openclaw/skills/spawn-coding-agent/SKILL.md"
CONFIG_PATH="/root/.openclaw/openclaw.json"
CODEX_CONFIG_PATH="/root/.codex/config.toml"
SSH_OPTS=(-o BatchMode=yes -i "${HOME}/.ssh/id_ed25519" -o IdentitiesOnly=yes -o PasswordAuthentication=no)

echo "Syncing spawn-coding-agent skill to ${HOST}..."
scp "${SSH_OPTS[@]}" "${SKILL_SRC}" "${HOST}:${SKILL_DST}"

echo "Applying OpenClaw coding workflow settings on ${HOST}..."
ssh "${SSH_OPTS[@]}" "${HOST}" \
  SENDER_ID="${SENDER_ID}" \
  REPO_PATH="${REPO_PATH}" \
  CONFIG_PATH="${CONFIG_PATH}" \
  CODEX_CONFIG_PATH="${CODEX_CONFIG_PATH}" \
  'python3 - <<'"'"'PY'"'"'
import json
import os
from pathlib import Path

sender_id = os.environ["SENDER_ID"]
repo_path = os.environ.get("REPO_PATH", "").strip()
config_path = Path(os.environ["CONFIG_PATH"])
codex_config_path = Path(os.environ["CODEX_CONFIG_PATH"])

raw = config_path.read_text()
data = json.loads(raw)

tools = data.setdefault("tools", {})
elevated = tools.setdefault("elevated", {})
elevated["enabled"] = True
allow_from = elevated.setdefault("allowFrom", {})
telegram = allow_from.setdefault("telegram", [])
for token in (sender_id, f"telegram:{sender_id}"):
    if token not in telegram:
        telegram.append(token)

agents = data.setdefault("agents", {}).setdefault("list", [])
seen_ids = set()
for agent in agents:
    agent_id = agent.get("id")
    seen_ids.add(agent_id)
    if agent_id in {"main", "coding-agent"}:
        exec_cfg = agent.setdefault("tools", {}).setdefault("exec", {})
        exec_cfg["ask"] = "off"

for missing_id in ("main", "coding-agent"):
    if missing_id not in seen_ids:
        agents.append({"id": missing_id, "tools": {"exec": {"ask": "off"}}})

backup = config_path.with_name("openclaw.json.bak-bootstrap-coding-mode")
backup.write_text(json.dumps(json.loads(raw), indent=2) + "\n")
config_path.write_text(json.dumps(data, indent=2) + "\n")

if repo_path:
    text = codex_config_path.read_text() if codex_config_path.exists() else ""
    marker = f'[projects."{repo_path}"]'
    if marker not in text:
        block = f'\n{marker}\ntrust_level = "trusted"\n'
        codex_config_path.write_text(text + block)

print(json.dumps({
    "config_backup": str(backup),
    "telegram_allow_from": telegram,
    "repo_trusted": repo_path or None,
}, indent=2))
PY'

echo "Restarting OpenClaw gateway on ${HOST}..."
ssh "${SSH_OPTS[@]}" "${HOST}" 'systemctl --user restart openclaw-gateway && sleep 2 && systemctl --user status openclaw-gateway --no-pager -n 10'

echo
echo "Done."
echo "Usage:"
echo "  $(basename "$0") [root@host] [telegram_sender_id] [/optional/repo/path]"
