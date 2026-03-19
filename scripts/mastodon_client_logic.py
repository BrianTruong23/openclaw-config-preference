#!/usr/bin/env python3

import json
import os
import urllib.parse
import urllib.request
from pathlib import Path


AUTH_PATH = Path(__file__).with_name("mastodon_auth.json")


def output_error(message: str) -> None:
    print(json.dumps({"posts": [], "error": message}))


def read_auth():
    if not AUTH_PATH.exists():
        raise RuntimeError(
            f"Missing auth file: {AUTH_PATH}. Populate mastodon_auth.json first."
        )
    data = json.loads(AUTH_PATH.read_text())
    base_url = data.get("base_url", "").rstrip("/")
    access_token = data.get("access_token", "").strip()
    client_id = data.get("client_id", "").strip()
    client_secret = data.get("client_secret", "").strip()
    if not base_url:
        raise RuntimeError("mastodon_auth.json is missing base_url")
    return {
        "base_url": base_url,
        "access_token": access_token,
        "client_id": client_id,
        "client_secret": client_secret,
    }


def api_request(base_url, path, token="", method="GET", form=None):
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = None
    if form is not None:
        data = urllib.parse.urlencode(form).encode()
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    req = urllib.request.Request(f"{base_url}{path}", data=data, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode())


def normalize_statuses(items):
    posts = []
    for item in items:
        account = item.get("account", {})
        posts.append(
            {
                "id": item.get("id", ""),
                "created_at": item.get("created_at", ""),
                "url": item.get("url", ""),
                "uri": item.get("uri", ""),
                "account_username": account.get("username", ""),
                "account_acct": account.get("acct", ""),
                "content": item.get("content", ""),
            }
        )
    return posts


if __name__ == "__main__":
    try:
        auth = read_auth()
        action = os.environ.get("OC_PARAM_ACTION", "").strip()
        query = os.environ.get("OC_PARAM_QUERY", "").strip()
        limit = max(1, min(int(os.environ.get("OC_PARAM_LIMIT", "10")), 40))
        text = os.environ.get("OC_PARAM_TEXT", "").strip()
        visibility = os.environ.get("OC_PARAM_VISIBILITY", "public").strip() or "public"

        if action == "search_posts":
            if not query:
                raise RuntimeError("query is required for search_posts")
            data = api_request(
                auth["base_url"],
                "/api/v2/search?" + urllib.parse.urlencode(
                    {"q": query, "type": "statuses", "limit": str(limit)}
                ),
                token=auth["access_token"],
            )
            print(json.dumps({"posts": normalize_statuses(data.get("statuses", []))}))
        elif action == "get_public_timeline":
            data = api_request(
                auth["base_url"],
                "/api/v1/timelines/public?" + urllib.parse.urlencode({"limit": str(limit)}),
                token=auth["access_token"],
            )
            print(json.dumps({"posts": normalize_statuses(data)}))
        elif action == "create_status":
            if not auth["access_token"]:
                raise RuntimeError("access_token is required in mastodon_auth.json for posting")
            if not text:
                raise RuntimeError("text is required for create_status")
            status = api_request(
                auth["base_url"],
                "/api/v1/statuses",
                token=auth["access_token"],
                method="POST",
                form={"status": text, "visibility": visibility},
            )
            print(json.dumps({"status": status}))
        else:
            raise RuntimeError(
                "action must be one of search_posts, get_public_timeline, create_status"
            )
    except Exception as exc:
        output_error(str(exc))
