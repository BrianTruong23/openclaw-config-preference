#!/usr/bin/env bash
set -euo pipefail

TOKEN_FILE="/root/.config/openclaw/google-drive/token.json"

if [ ! -f "${TOKEN_FILE}" ]; then
  echo "Missing Google Drive token: ${TOKEN_FILE}" >&2
  exit 1
fi

# Refresh the OpenClaw Google token when needed before handing it to gws.
gdrive-doc status --resolve-default-folder >/dev/null

export GOOGLE_WORKSPACE_CLI_TOKEN="$(
  python3 - <<'PY'
import json
from pathlib import Path
token = json.loads(Path("/root/.config/openclaw/google-drive/token.json").read_text())["token"]
print(token)
PY
)"

exec gws "$@"
