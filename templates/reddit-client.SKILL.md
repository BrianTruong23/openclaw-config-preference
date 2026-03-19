openclaw:
  description: Query public Reddit posts and submit text or link posts using Reddit OAuth credentials from environment variables.
  emoji: "👽"
  parameters:
    action:
      type: string
      description: One of search_posts, submit_text_post, submit_link_post.
      required: true
    subreddit:
      type: string
      description: Subreddit name without /r/ prefix.
      required: true
    query:
      type: string
      description: Search query for search_posts.
      required: false
    limit:
      type: integer
      description: Maximum number of search results to return.
      default: 10
      minimum: 1
      maximum: 100
    sort:
      type: string
      description: Search sort for search_posts. One of relevance, hot, top, new, comments.
      default: relevance
      required: false
    title:
      type: string
      description: Post title for submit_text_post or submit_link_post.
      required: false
    text:
      type: string
      description: Text body for submit_text_post.
      required: false
    url:
      type: string
      description: Target URL for submit_link_post.
      required: false
    nsfw:
      type: boolean
      description: Whether to mark the submission NSFW.
      default: false
      required: false
  returns:
    posts:
      type: array
      description: Search results when action=search_posts.
      items:
        type: object
        properties:
          id:
            type: string
          title:
            type: string
          author:
            type: string
          subreddit:
            type: string
          score:
            type: integer
          num_comments:
            type: integer
          created_utc:
            type: number
          permalink:
            type: string
          url:
            type: string
    submission:
      type: object
      description: Submission result for submit actions.
      properties:
        id:
          type: string
        name:
          type: string
        permalink:
          type: string
        url:
          type: string
    error:
      type: string
      description: Error message if the Reddit API request fails.
  entrypoint: python reddit_client_logic.py
