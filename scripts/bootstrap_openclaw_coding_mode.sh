#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-root@76.13.24.24}"
SENDER_ID="${2:-7810829778}"
REPO_PATH="${3:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_SRC="${ROOT_DIR}/templates/spawn-coding-agent.SKILL.md"
SKILL_DST="/root/.openclaw/skills/spawn-coding-agent/SKILL.md"
GDRIVE_SKILL_SRC="${ROOT_DIR}/templates/google-drive-docs.SKILL.md"
GDRIVE_SKILL_YAML_SRC="${ROOT_DIR}/templates/google-drive-docs.openai.yaml"
GDRIVE_HELPER_SRC="${ROOT_DIR}/scripts/gdrive_doc_remote.py"
GWS_WRAPPER_SRC="${ROOT_DIR}/scripts/gws_openclaw.sh"
X_POSTS_READER_SRC="${ROOT_DIR}/templates/x-posts-reader.SKILL.md"
X_POSTS_READER_YAML_SRC="${ROOT_DIR}/templates/x-posts-reader.openai.yaml"
X_POSTS_READER_LOGIC_SRC="${ROOT_DIR}/scripts/x_posts_reader_logic.py"
WORKSPACE_AGENTS_SRC="${ROOT_DIR}/templates/openclaw-workspace-AGENTS.md"
CLAWHUB_WRAPPER_SRC="${ROOT_DIR}/scripts/openclaw_skillhub.sh"
CLAWHUB_SKILL_SRC="${ROOT_DIR}/templates/clawhub-skills.SKILL.md"
CLAWHUB_SKILL_YAML_SRC="${ROOT_DIR}/templates/clawhub-skills.openai.yaml"
GOOGLE_WORKSPACE_SKILL_SRC="${ROOT_DIR}/templates/google-workspace.SKILL.md"
GOOGLE_WORKSPACE_SKILL_YAML_SRC="${ROOT_DIR}/templates/google-workspace.openai.yaml"
GDRIVE_SKILL_DIR="/root/.openclaw/skills/google-drive-docs"
GDRIVE_SKILL_DST="${GDRIVE_SKILL_DIR}/SKILL.md"
GDRIVE_SKILL_YAML_DST="${GDRIVE_SKILL_DIR}/agents/openai.yaml"
GDRIVE_HELPER_DST="${GDRIVE_SKILL_DIR}/bin/gdrive_doc.py"
GWS_WRAPPER_DST="/usr/local/bin/gws-openclaw"
CLAWHUB_WRAPPER_DST="/usr/local/bin/openclaw-skillhub"
CLAWHUB_SKILL_DIR="/root/.openclaw/skills/clawhub-skills"
CLAWHUB_SKILL_DST="${CLAWHUB_SKILL_DIR}/SKILL.md"
CLAWHUB_SKILL_YAML_DST="${CLAWHUB_SKILL_DIR}/agents/openai.yaml"
GOOGLE_WORKSPACE_SKILL_DIR="/root/.openclaw/skills/google-workspace"
GOOGLE_WORKSPACE_SKILL_DST="${GOOGLE_WORKSPACE_SKILL_DIR}/SKILL.md"
GOOGLE_WORKSPACE_SKILL_YAML_DST="${GOOGLE_WORKSPACE_SKILL_DIR}/agents/openai.yaml"
WORKSPACE_AGENTS_DST="/root/.openclaw/workspace/AGENTS.md"
WORKSPACE_CODING_AGENTS_DST="/root/.openclaw/workspace-coding/AGENTS.md"
X_POSTS_READER_DIR="/root/.openclaw/skills/x-posts-reader"
X_POSTS_READER_DST="${X_POSTS_READER_DIR}/SKILL.md"
X_POSTS_READER_YAML_DST="${X_POSTS_READER_DIR}/agents/openai.yaml"
X_POSTS_READER_LOGIC_DST="${X_POSTS_READER_DIR}/x_posts_reader_logic.py"
CONFIG_PATH="/root/.openclaw/openclaw.json"
CODEX_CONFIG_PATH="/root/.codex/config.toml"
SERVICE_ENV_PATH="/root/.config/openclaw/openclaw.env"
SSH_OPTS=(-o BatchMode=yes -i "${HOME}/.ssh/id_ed25519" -o IdentitiesOnly=yes -o PasswordAuthentication=no)
DEFAULT_CLAWHUB_SKILLS=(
  "agent-browser-clawdbot"
  "agent-daily-planner"
  "agent-swarm"
  "agent-team-orchestration"
  "self-reflection"
  "joko-moltbook"
  "tweet-writer"
  "us-stock-analysis"
  "csv-pipeline"
  "automation-workflows"
  "free-ride"
  "mac-tts"
  "n8n"
  "clawtoclaw"
)
FORCED_CLAWHUB_SKILLS=(
)

echo "Installing GitHub CLI on ${HOST}..."
ssh "${SSH_OPTS[@]}" "${HOST}" 'apt-get update && apt-get install -y gh'

echo "Installing Google Workspace CLI on ${HOST}..."
ssh "${SSH_OPTS[@]}" "${HOST}" 'npm install -g @googleworkspace/cli'

echo "Installing ClawHub CLI on ${HOST}..."
ssh "${SSH_OPTS[@]}" "${HOST}" 'npm install -g clawhub'

echo "Syncing spawn-coding-agent skill to ${HOST}..."
scp "${SSH_OPTS[@]}" "${SKILL_SRC}" "${HOST}:${SKILL_DST}"

echo "Syncing Google Drive skill to ${HOST}..."
ssh "${SSH_OPTS[@]}" "${HOST}" "mkdir -p ${GDRIVE_SKILL_DIR}/agents ${GDRIVE_SKILL_DIR}/bin"
scp "${SSH_OPTS[@]}" "${GDRIVE_SKILL_SRC}" "${HOST}:${GDRIVE_SKILL_DST}"
scp "${SSH_OPTS[@]}" "${GDRIVE_SKILL_YAML_SRC}" "${HOST}:${GDRIVE_SKILL_YAML_DST}"
scp "${SSH_OPTS[@]}" "${GDRIVE_HELPER_SRC}" "${HOST}:${GDRIVE_HELPER_DST}"
scp "${SSH_OPTS[@]}" "${GWS_WRAPPER_SRC}" "${HOST}:${GWS_WRAPPER_DST}"
scp "${SSH_OPTS[@]}" "${WORKSPACE_AGENTS_SRC}" "${HOST}:${WORKSPACE_AGENTS_DST}"
scp "${SSH_OPTS[@]}" "${WORKSPACE_AGENTS_SRC}" "${HOST}:${WORKSPACE_CODING_AGENTS_DST}"
ssh "${SSH_OPTS[@]}" "${HOST}" "mkdir -p ${CLAWHUB_SKILL_DIR}/agents"
scp "${SSH_OPTS[@]}" "${CLAWHUB_WRAPPER_SRC}" "${HOST}:${CLAWHUB_WRAPPER_DST}"
scp "${SSH_OPTS[@]}" "${CLAWHUB_SKILL_SRC}" "${HOST}:${CLAWHUB_SKILL_DST}"
scp "${SSH_OPTS[@]}" "${CLAWHUB_SKILL_YAML_SRC}" "${HOST}:${CLAWHUB_SKILL_YAML_DST}"
ssh "${SSH_OPTS[@]}" "${HOST}" "mkdir -p ${X_POSTS_READER_DIR}/agents"
scp "${SSH_OPTS[@]}" "${X_POSTS_READER_SRC}" "${HOST}:${X_POSTS_READER_DST}"
scp "${SSH_OPTS[@]}" "${X_POSTS_READER_YAML_SRC}" "${HOST}:${X_POSTS_READER_YAML_DST}"
scp "${SSH_OPTS[@]}" "${X_POSTS_READER_LOGIC_SRC}" "${HOST}:${X_POSTS_READER_LOGIC_DST}"
ssh "${SSH_OPTS[@]}" "${HOST}" "mkdir -p ${GOOGLE_WORKSPACE_SKILL_DIR}/agents"
scp "${SSH_OPTS[@]}" "${GOOGLE_WORKSPACE_SKILL_SRC}" "${HOST}:${GOOGLE_WORKSPACE_SKILL_DST}"
scp "${SSH_OPTS[@]}" "${GOOGLE_WORKSPACE_SKILL_YAML_SRC}" "${HOST}:${GOOGLE_WORKSPACE_SKILL_YAML_DST}"

echo "Installing default ClawHub skills on ${HOST}..."
for skill in "${DEFAULT_CLAWHUB_SKILLS[@]}"; do
  ssh "${SSH_OPTS[@]}" "${HOST}" "${CLAWHUB_WRAPPER_DST} install ${skill} --no-input || true"
done
for skill in "${FORCED_CLAWHUB_SKILLS[@]}"; do
  ssh "${SSH_OPTS[@]}" "${HOST}" "${CLAWHUB_WRAPPER_DST} install ${skill} --no-input --force || true"
done

echo "Installing Google Drive skill runtime on ${HOST}..."
ssh "${SSH_OPTS[@]}" "${HOST}" "
  apt-get update &&
  apt-get install -y python3-venv &&
  mkdir -p /root/.config/gws &&
  python3 -m venv ${GDRIVE_SKILL_DIR}/.venv &&
  ${GDRIVE_SKILL_DIR}/.venv/bin/pip install --upgrade pip &&
  ${GDRIVE_SKILL_DIR}/.venv/bin/pip install google-api-python-client google-auth google-auth-oauthlib &&
  python3 - <<'PY'
import json
from pathlib import Path

token_file = Path('/root/.config/openclaw/google-drive/token.json')
credentials_file = Path('/root/.config/gws/credentials.json')

if token_file.exists():
    data = json.loads(token_file.read_text())
    credentials = {
        'type': 'authorized_user',
        'client_id': data['client_id'],
        'client_secret': data['client_secret'],
        'refresh_token': data['refresh_token'],
    }
    credentials_file.write_text(json.dumps(credentials))
    credentials_file.chmod(0o600)
PY
  chmod +x ${GDRIVE_HELPER_DST} ${X_POSTS_READER_LOGIC_DST} &&
  printf '%s\n' '#!/bin/sh' 'exec ${GDRIVE_SKILL_DIR}/.venv/bin/python ${GDRIVE_HELPER_DST} \"\$@\"' > /usr/local/bin/gdrive-doc &&
  chmod +x /usr/local/bin/gdrive-doc ${GWS_WRAPPER_DST} ${CLAWHUB_WRAPPER_DST}
"

echo "Applying OpenClaw coding workflow settings on ${HOST}..."
ssh "${SSH_OPTS[@]}" "${HOST}" \
  SENDER_ID="${SENDER_ID}" \
  REPO_PATH="${REPO_PATH}" \
  CONFIG_PATH="${CONFIG_PATH}" \
  CODEX_CONFIG_PATH="${CODEX_CONFIG_PATH}" \
  SERVICE_ENV_PATH="${SERVICE_ENV_PATH}" \
  'python3 - <<'"'"'PY'"'"'
import json
import os
from pathlib import Path

sender_id = os.environ["SENDER_ID"]
repo_path = os.environ.get("REPO_PATH", "").strip()
config_path = Path(os.environ["CONFIG_PATH"])
codex_config_path = Path(os.environ["CODEX_CONFIG_PATH"])
service_env_path = Path(os.environ["SERVICE_ENV_PATH"])

raw = config_path.read_text()
data = json.loads(raw)

tools = data.setdefault("tools", {})
tools["profile"] = "coding"
elevated = tools.setdefault("elevated", {})
elevated["enabled"] = True
allow_from = elevated.setdefault("allowFrom", {})
telegram = allow_from.setdefault("telegram", [])
for token in (sender_id, f"telegram:{sender_id}"):
    if token not in telegram:
        telegram.append(token)
exec_global = tools.setdefault("exec", {})
exec_global["security"] = "full"
exec_global.setdefault("applyPatch", {})["enabled"] = True
exec_global.setdefault("applyPatch", {})["workspaceOnly"] = True
approvals = data.setdefault("approvals", {})
approvals_exec = approvals.setdefault("exec", {})
approvals_exec["enabled"] = True
approvals_exec["mode"] = "session"

agents = data.setdefault("agents", {}).setdefault("list", [])
seen_ids = set()
for agent in agents:
    agent_id = agent.get("id")
    seen_ids.add(agent_id)
    if agent_id in {"main", "coding-agent"}:
        exec_cfg = agent.setdefault("tools", {}).setdefault("exec", {})
        exec_cfg["ask"] = "off"
    if agent_id == "coding-agent":
        agent["model"] = "openrouter/google/gemini-2.5-flash"

for missing_id in ("main", "coding-agent"):
    if missing_id not in seen_ids:
        item = {"id": missing_id, "tools": {"exec": {"ask": "off"}}}
        if missing_id == "coding-agent":
            item["model"] = "openrouter/google/gemini-2.5-flash"
        agents.append(item)

backup = config_path.with_name("openclaw.json.bak-bootstrap-coding-mode")
backup.write_text(json.dumps(json.loads(raw), indent=2) + "\n")
config_path.write_text(json.dumps(data, indent=2) + "\n")

if repo_path:
    text = codex_config_path.read_text() if codex_config_path.exists() else ""
    marker = f'[projects."{repo_path}"]'
    if marker not in text:
        block = f'\n{marker}\ntrust_level = "trusted"\n'
        codex_config_path.write_text(text + block)

gh_ready = False
if service_env_path.exists():
    env_text = service_env_path.read_text()
    gh_ready = "GITHUB_TOKEN=" in env_text and "GITHUB_TOKEN=\n" not in env_text and "GITHUB_TOKEN=" != env_text.strip()

print(json.dumps({
    "config_backup": str(backup),
    "telegram_allow_from": telegram,
    "repo_trusted": repo_path or None,
    "gh_uses_service_env_token": gh_ready,
    "coding_agent_model": "openrouter/google/gemini-2.5-flash",
}, indent=2))
PY'

echo "Restarting OpenClaw gateway on ${HOST}..."
ssh "${SSH_OPTS[@]}" "${HOST}" 'systemctl --user restart openclaw-gateway && sleep 2 && systemctl --user status openclaw-gateway --no-pager -n 10'

echo
echo "Done."
echo "GitHub CLI auth note:"
echo "  gh will use GITHUB_TOKEN from /root/.config/openclaw/openclaw.env when OpenClaw or a sourced shell runs it."
echo "Usage:"
echo "  $(basename "$0") [root@host] [telegram_sender_id] [/optional/repo/path]"
