#!/usr/bin/env bash
set -euo pipefail

TOKEN_FILE="/root/.config/openclaw/google-drive/token.json"
GWS_CREDENTIALS_FILE="/root/.config/gws/credentials.json"
GWS_ENCRYPTED_CREDENTIALS_FILE="/root/.config/gws/credentials.enc"

# Prefer native gws auth when it exists. This supports broader scopes like
# Gmail and Calendar and avoids forcing the narrower OpenClaw Drive token.
if [ -f "${GWS_CREDENTIALS_FILE}" ] || [ -f "${GWS_ENCRYPTED_CREDENTIALS_FILE}" ]; then
  exec gws "$@"
fi

if [ ! -f "${TOKEN_FILE}" ]; then
  echo "Missing Google auth. Expected native gws credentials under /root/.config/gws or OpenClaw Drive token at ${TOKEN_FILE}" >&2
  exit 1
fi

# Fall back to the OpenClaw Google Drive token when native gws auth is absent.
# This path is sufficient for Drive-oriented operations but may lack Gmail or
# Calendar scopes.
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
