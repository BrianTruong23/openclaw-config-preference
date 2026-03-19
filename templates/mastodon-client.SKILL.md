openclaw:
  description: Query public Mastodon posts and create statuses using Mastodon API credentials from a local auth JSON file.
  emoji: "🐘"
  parameters:
    action:
      type: string
      description: One of search_posts, get_public_timeline, create_status.
      required: true
    query:
      type: string
      description: Search query for search_posts.
      required: false
    limit:
      type: integer
      description: Maximum number of results to return.
      default: 10
      minimum: 1
      maximum: 40
    text:
      type: string
      description: Status text for create_status.
      required: false
    visibility:
      type: string
      description: Visibility for create_status. One of public, unlisted, private, direct.
      default: public
      required: false
  returns:
    posts:
      type: array
      description: Returned statuses when action is search_posts or get_public_timeline.
      items:
        type: object
        properties:
          id:
            type: string
          created_at:
            type: string
          url:
            type: string
          uri:
            type: string
          account_username:
            type: string
          account_acct:
            type: string
          content:
            type: string
    status:
      type: object
      description: Created status when action is create_status.
    error:
      type: string
      description: Error message if the Mastodon API request fails.
  entrypoint: python mastodon_client_logic.py
