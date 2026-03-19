#!/usr/bin/env bash
set -euo pipefail

TOKEN_FILE="/root/.config/openclaw/google-drive/token.json"
GWS_CREDENTIALS_FILE="/root/.config/gws/credentials.json"
GWS_ENCRYPTED_CREDENTIALS_FILE="/root/.config/gws/credentials.enc"

sync_gws_credentials_from_openclaw_token() {
  mkdir -p "$(dirname "${GWS_CREDENTIALS_FILE}")"
  python3 - <<'PY'
import json
from pathlib import Path

token_file = Path("/root/.config/openclaw/google-drive/token.json")
credentials_file = Path("/root/.config/gws/credentials.json")

data = json.loads(token_file.read_text())
credentials = {
    "type": "authorized_user",
    "client_id": data["client_id"],
    "client_secret": data["client_secret"],
    "refresh_token": data["refresh_token"],
}

credentials_file.write_text(json.dumps(credentials))
credentials_file.chmod(0o600)
PY
}

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
sync_gws_credentials_from_openclaw_token

export GOOGLE_WORKSPACE_CLI_TOKEN="$(
  python3 - <<'PY'
import json
from pathlib import Path
token = json.loads(Path("/root/.config/openclaw/google-drive/token.json").read_text())["token"]
print(token)
PY
)"

exec gws "$@"
