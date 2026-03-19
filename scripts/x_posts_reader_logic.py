#!/usr/bin/env python3

import json
import os
from urllib.parse import unquote

import requests


def error(message: str) -> None:
    print(json.dumps({"posts": [], "error": message}))


if __name__ == "__main__":
    query = os.environ.get("OC_PARAM_QUERY")
    limit = int(os.environ.get("OC_PARAM_LIMIT", 10))
    bearer_token = unquote(os.environ.get("X_BEARER_TOKEN", "").strip())

    if not query:
        error("Missing required parameter: query")
        raise SystemExit(0)

    if not bearer_token:
        error("X_BEARER_TOKEN is not configured in the environment.")
        raise SystemExit(0)

    headers = {"Authorization": f"Bearer {bearer_token}"}
    api_url = "https://api.twitter.com/2/tweets/search/recent"
    params = {
        "query": query,
        "max_results": max(10, min(limit, 100)),
        "tweet.fields": "created_at,author_id",
        "expansions": "author_id",
        "user.fields": "username",
    }

    try:
        response = requests.get(api_url, headers=headers, params=params, timeout=30)
        if response.status_code == 402:
            error(
                "X API recent search is not available for this token or plan. "
                "The endpoint returned 402 Payment Required."
            )
            raise SystemExit(0)
        response.raise_for_status()
        response_data = response.json()
        users = {
            user["id"]: user["username"]
            for user in response_data.get("includes", {}).get("users", [])
        }

        posts = []
        for tweet in response_data.get("data", []):
            author_username = users.get(tweet.get("author_id"), "unknown")
            tweet_id = tweet.get("id", "")
            posts.append(
                {
                    "id": tweet_id,
                    "text": tweet.get("text", ""),
                    "author_username": author_username,
                    "created_at": tweet.get("created_at", ""),
                    "url": f"https://twitter.com/{author_username}/status/{tweet_id}",
                }
            )

        print(json.dumps({"posts": posts}))
    except requests.exceptions.RequestException as exc:
        error(f"Error fetching posts from X: {exc}")
    except json.JSONDecodeError:
        error(f"Error decoding JSON response from X API: {response.text}")
