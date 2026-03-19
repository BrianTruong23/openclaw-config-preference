openclaw:
  description: Reads public posts from X based on a search query using the X API v2 recent-search endpoint and an `X_BEARER_TOKEN` environment variable.
  emoji: "🐦"
  parameters:
    query:
      type: string
      description: The X search query string.
      required: true
    limit:
      type: integer
      description: Maximum number of posts to fetch.
      default: 10
      minimum: 10
      maximum: 100
  returns:
    posts:
      type: array
      description: Matching X posts.
      items:
        type: object
        properties:
          id:
            type: string
          text:
            type: string
          author_username:
            type: string
          created_at:
            type: string
          url:
            type: string
    error:
      type: string
      description: Error message if the X API request fails.
  entrypoint: python x_posts_reader_logic.py
