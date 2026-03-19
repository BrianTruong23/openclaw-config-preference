#!/usr/bin/env python3

import base64
import json
import os
import urllib.parse
import urllib.request


TOKEN_URL = "https://www.reddit.com/api/v1/access_token"
OAUTH_BASE = "https://oauth.reddit.com"


def error(message: str) -> None:
    print(json.dumps({"posts": [], "error": message}))


def bool_param(name: str, default: bool = False) -> bool:
    raw = os.environ.get(name)
    if raw is None:
        return default
    return raw.lower() in {"1", "true", "yes", "on"}


def env_required(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def get_token(for_posting: bool) -> str:
    client_id = env_required("REDDIT_CLIENT_ID")
    client_secret = env_required("REDDIT_CLIENT_SECRET")
    user_agent = env_required("REDDIT_USER_AGENT")

    username = os.environ.get("REDDIT_USERNAME", "").strip()
    password = os.environ.get("REDDIT_PASSWORD", "").strip()

    if for_posting:
        if not username or not password:
            raise RuntimeError(
                "REDDIT_USERNAME and REDDIT_PASSWORD are required for posting."
            )
        form = {
            "grant_type": "password",
            "username": username,
            "password": password,
        }
    else:
        form = {"grant_type": "client_credentials"}

    body = urllib.parse.urlencode(form).encode()
    basic = base64.b64encode(f"{client_id}:{client_secret}".encode()).decode()
    req = urllib.request.Request(
        TOKEN_URL,
        data=body,
        headers={
            "Authorization": f"Basic {basic}",
            "User-Agent": user_agent,
            "Content-Type": "application/x-www-form-urlencoded",
        },
        method="POST",
    )

    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.loads(resp.read().decode())
    token = data.get("access_token")
    if not token:
        raise RuntimeError(f"Reddit OAuth failed: {json.dumps(data)}")
    return token


def api_request(path: str, token: str, user_agent: str, method: str = "GET", form=None):
    headers = {
        "Authorization": f"bearer {token}",
        "User-Agent": user_agent,
    }
    data = None
    if form is not None:
        data = urllib.parse.urlencode(form).encode()
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    req = urllib.request.Request(
        f"{OAUTH_BASE}{path}",
        data=data,
        headers=headers,
        method=method,
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode())


if __name__ == "__main__":
    try:
        action = os.environ.get("OC_PARAM_ACTION", "").strip()
        subreddit = os.environ.get("OC_PARAM_SUBREDDIT", "").strip()
        query = os.environ.get("OC_PARAM_QUERY", "").strip()
        limit = max(1, min(int(os.environ.get("OC_PARAM_LIMIT", "10")), 100))
        sort = os.environ.get("OC_PARAM_SORT", "relevance").strip() or "relevance"
        title = os.environ.get("OC_PARAM_TITLE", "").strip()
        text = os.environ.get("OC_PARAM_TEXT", "").strip()
        url = os.environ.get("OC_PARAM_URL", "").strip()
        nsfw = bool_param("OC_PARAM_NSFW", False)
        user_agent = env_required("REDDIT_USER_AGENT")

        if not subreddit:
            raise RuntimeError("Missing required parameter: subreddit")

        if action == "search_posts":
            if not query:
                raise RuntimeError("query is required for search_posts")
            token = get_token(for_posting=False)
            path = (
                f"/r/{urllib.parse.quote(subreddit)}/search?"
                + urllib.parse.urlencode(
                    {
                        "q": query,
                        "restrict_sr": "1",
                        "sort": sort,
                        "limit": str(limit),
                        "raw_json": "1",
                    }
                )
            )
            data = api_request(path, token, user_agent)
            posts = []
            for child in data.get("data", {}).get("children", []):
                post = child.get("data", {})
                posts.append(
                    {
                        "id": post.get("id", ""),
                        "title": post.get("title", ""),
                        "author": post.get("author", ""),
                        "subreddit": post.get("subreddit", ""),
                        "score": post.get("score", 0),
                        "num_comments": post.get("num_comments", 0),
                        "created_utc": post.get("created_utc", 0),
                        "permalink": f"https://www.reddit.com{post.get('permalink', '')}",
                        "url": post.get("url_overridden_by_dest")
                        or post.get("url")
                        or "",
                    }
                )
            print(json.dumps({"posts": posts}))

        elif action in {"submit_text_post", "submit_link_post"}:
            if not title:
                raise RuntimeError("title is required for submit actions")
            token = get_token(for_posting=True)
            form = {
                "api_type": "json",
                "sr": subreddit,
                "title": title,
                "nsfw": "true" if nsfw else "false",
                "resubmit": "true",
                "sendreplies": "true",
            }
            if action == "submit_text_post":
                if not text:
                    raise RuntimeError("text is required for submit_text_post")
                form.update({"kind": "self", "text": text})
            else:
                if not url:
                    raise RuntimeError("url is required for submit_link_post")
                form.update({"kind": "link", "url": url})

            result = api_request("/api/submit", token, user_agent, method="POST", form=form)
            json_result = result.get("json", {})
            errors = json_result.get("errors", [])
            if errors:
                raise RuntimeError(f"Reddit submit failed: {json.dumps(errors)}")
            data = json_result.get("data", {})
            print(
                json.dumps(
                    {
                        "submission": {
                            "id": data.get("id", ""),
                            "name": data.get("name", ""),
                            "permalink": data.get("url", ""),
                            "url": data.get("url", ""),
                        }
                    }
                )
            )
        else:
            raise RuntimeError(
                "action must be one of search_posts, submit_text_post, submit_link_post"
            )

    except Exception as exc:
        error(str(exc))
