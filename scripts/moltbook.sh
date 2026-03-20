#!/usr/bin/env bash
set -euo pipefail

# Patched Moltbook CLI helper for OpenClaw baseline.
# Main fixes:
# - avoid unsafe JSON string interpolation
# - stop defaulting submolt_name to a stale UUID
# - expose HTTP status/body so failures are debuggable

CONFIG_FILE="${HOME}/.config/moltbook/credentials.json"
OPENCLAW_AUTH="${HOME}/.openclaw/auth-profiles.json"
API_BASE="${MOLTBOOK_API_BASE:-https://www.moltbook.com/api/v1}"
DEFAULT_SUBMOLT_NAME="${MOLTBOOK_SUBMOLT_NAME:-general}"

API_KEY=""

if [[ -f "$OPENCLAW_AUTH" ]] && command -v jq >/dev/null 2>&1; then
    API_KEY="$(jq -r '.moltbook.api_key // empty' "$OPENCLAW_AUTH" 2>/dev/null)"
fi

if [[ -z "$API_KEY" && -f "$CONFIG_FILE" ]]; then
    if command -v jq >/dev/null 2>&1; then
        API_KEY="$(jq -r '.api_key // empty' "$CONFIG_FILE" 2>/dev/null)"
    else
        API_KEY="$(grep '"api_key"' "$CONFIG_FILE" | sed 's/.*"api_key"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true)"
    fi
fi

if [[ -z "$API_KEY" || "$API_KEY" == "null" ]]; then
    echo "Error: Moltbook credentials not found"
    echo ""
    echo "Option 1 - OpenClaw auth (recommended):"
    echo "  openclaw agents auth add moltbook --token your_api_key"
    echo ""
    echo "Option 2 - Credentials file:"
    echo "  mkdir -p ~/.config/moltbook"
    echo "  echo '{\"api_key\":\"your_key\",\"agent_name\":\"YourName\"}' > ~/.config/moltbook/credentials.json"
    exit 1
fi

is_uuid_like() {
    [[ "${1:-}" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]
}

require_non_uuid_submolt() {
    local submolt="${1:-}"
    if [[ -z "$submolt" ]]; then
        echo "Error: submolt_name is required" >&2
        exit 1
    fi
    if is_uuid_like "$submolt"; then
        echo "Error: submolt_name looks like a UUID: $submolt" >&2
        echo "The Moltbook API field is named submolt_name. Use a real submolt name such as 'general' or set MOLTBOOK_ALLOW_SUBMOLT_UUID=1 to override." >&2
        if [[ "${MOLTBOOK_ALLOW_SUBMOLT_UUID:-0}" != "1" ]]; then
            exit 1
        fi
    fi
}

build_post_payload() {
    local title="$1"
    local content="$2"
    local submolt_name="$3"
    if command -v jq >/dev/null 2>&1; then
        jq -cn \
            --arg title "$title" \
            --arg content "$content" \
            --arg submolt_name "$submolt_name" \
            '{title:$title, content:$content, submolt_name:$submolt_name}'
    else
        python3 - "$title" "$content" "$submolt_name" <<'PY'
import json
import sys
print(json.dumps({
    "title": sys.argv[1],
    "content": sys.argv[2],
    "submolt_name": sys.argv[3],
}))
PY
    fi
}

api_call() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local body_file
    local status
    body_file="$(mktemp)"

    if [[ -n "$data" ]]; then
        status="$(
            curl -sS -o "$body_file" -w '%{http_code}' -X "$method" "${API_BASE}${endpoint}" \
                -H "Authorization: Bearer ${API_KEY}" \
                -H "Content-Type: application/json" \
                -d "$data"
        )"
    else
        status="$(
            curl -sS -o "$body_file" -w '%{http_code}' -X "$method" "${API_BASE}${endpoint}" \
                -H "Authorization: Bearer ${API_KEY}" \
                -H "Content-Type: application/json"
        )"
    fi

    printf 'HTTP %s\n' "$status"
    cat "$body_file"
    rm -f "$body_file"

    [[ "$status" =~ ^2[0-9][0-9]$ ]]
}

create_from_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Error: file not found: $file" >&2
        exit 1
    fi

    local title
    local content
    local submolt_name

    if command -v jq >/dev/null 2>&1; then
        title="$(jq -r '.title // empty' "$file")"
        content="$(jq -r '.content // empty' "$file")"
        submolt_name="$(jq -r '.submolt_name // empty' "$file")"
    else
        readarray -t parsed < <(python3 - "$file" <<'PY'
import json
import sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text())
for key in ("title", "content", "submolt_name"):
    print(data.get(key, ""))
PY
        )
        title="${parsed[0]:-}"
        content="${parsed[1]:-}"
        submolt_name="${parsed[2]:-}"
    fi

    if [[ -z "$title" || -z "$content" ]]; then
        echo "Error: payload file must include title and content" >&2
        exit 1
    fi

    submolt_name="${submolt_name:-$DEFAULT_SUBMOLT_NAME}"
    require_non_uuid_submolt "$submolt_name"

    echo "Creating post from file: $file"
    echo "Using submolt_name: $submolt_name"
    api_call POST "/posts" "$(build_post_payload "$title" "$content" "$submolt_name")"
}

case "${1:-}" in
    hot)
        limit="${2:-10}"
        echo "Fetching hot posts..."
        api_call GET "/posts?sort=hot&limit=${limit}"
        ;;
    new)
        limit="${2:-10}"
        echo "Fetching new posts..."
        api_call GET "/posts?sort=new&limit=${limit}"
        ;;
    post)
        post_id="${2:-}"
        if [[ -z "$post_id" ]]; then
            echo "Usage: moltbook post POST_ID" >&2
            exit 1
        fi
        api_call GET "/posts/${post_id}"
        ;;
    reply)
        post_id="${2:-}"
        content="${3:-}"
        if [[ -z "$post_id" || -z "$content" ]]; then
            echo "Usage: moltbook reply POST_ID CONTENT" >&2
            exit 1
        fi
        echo "Posting reply..."
        if command -v jq >/dev/null 2>&1; then
            payload="$(jq -cn --arg content "$content" '{content:$content}')"
        else
            payload="$(python3 - "$content" <<'PY'
import json
import sys
print(json.dumps({"content": sys.argv[1]}))
PY
)"
        fi
        api_call POST "/posts/${post_id}/comments" "$payload"
        ;;
    create)
        title="${2:-}"
        content="${3:-}"
        submolt_name="${4:-$DEFAULT_SUBMOLT_NAME}"
        if [[ -z "$title" || -z "$content" ]]; then
            echo "Usage: moltbook create TITLE CONTENT [SUBMOLT_NAME]" >&2
            exit 1
        fi
        require_non_uuid_submolt "$submolt_name"
        echo "Creating post..."
        echo "Using submolt_name: $submolt_name"
        api_call POST "/posts" "$(build_post_payload "$title" "$content" "$submolt_name")"
        ;;
    create-file)
        payload_file="${2:-}"
        if [[ -z "$payload_file" ]]; then
            echo "Usage: moltbook create-file /path/to/post.json" >&2
            exit 1
        fi
        create_from_file "$payload_file"
        ;;
    verify)
        verification_code="${2:-}"
        answer="${3:-}"
        if [[ -z "$verification_code" || -z "$answer" ]]; then
            echo "Usage: moltbook verify VERIFICATION_CODE ANSWER" >&2
            exit 1
        fi
        echo "Submitting verification..."
        if command -v jq >/dev/null 2>&1; then
            payload="$(jq -cn --arg verification_code "$verification_code" --arg answer "$answer" '{verification_code:$verification_code, answer:$answer}')"
        else
            payload="$(python3 - "$verification_code" "$answer" <<'PY'
import json
import sys
print(json.dumps({"verification_code": sys.argv[1], "answer": sys.argv[2]}))
PY
)"
        fi
        api_call POST "/verify" "$payload"
        ;;
    test)
        echo "Testing Moltbook API connection..."
        api_call GET "/posts?sort=hot&limit=1"
        ;;
    *)
        echo "Moltbook CLI - Interact with Moltbook social network"
        echo ""
        echo "Usage: moltbook [command] [args]"
        echo ""
        echo "Commands:"
        echo "  hot [limit]                    Get hot posts"
        echo "  new [limit]                    Get new posts"
        echo "  post ID                        Get specific post"
        echo "  reply POST_ID TEXT             Reply to a post"
        echo "  create TITLE CONTENT [NAME]    Create new post with submolt_name"
        echo "  create-file FILE               Create a post from JSON payload file"
        echo "  verify CODE ANSWER             Submit verification"
        echo "  test                           Test API connection"
        echo ""
        echo "Environment:"
        echo "  MOLTBOOK_SUBMOLT_NAME          Default submolt_name (defaults to 'general')"
        echo "  MOLTBOOK_ALLOW_SUBMOLT_UUID=1  Override the UUID guard if the API truly expects one"
        echo ""
        echo "Examples:"
        echo "  moltbook hot 5"
        echo "  moltbook create-file /root/.openclaw/workspace/moltbook_post.json"
        ;;
esac
