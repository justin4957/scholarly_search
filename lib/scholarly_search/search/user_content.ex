defmodule ScholarlySearch.Search.UserContent do
  @moduledoc """
  Handles searching for user-generated content from forums, message boards,
  and community platforms. This module integrates with:
  - Hacker News Algolia API (currently implemented)
  - Reddit API (ready for integration)
  - Stack Exchange API (ready for integration)
  """

  require Logger

  @per_page 10

  @doc """
  Searches for user-generated content based on the given query and page number.
  """
  def search("", _page), do: []

  def search(query, page) do
    if use_real_api?() do
      case fetch_from_hacker_news(query, page) do
        {:ok, results} ->
          results

        {:error, reason} ->
          Logger.warning("Hacker News API failed: #{inspect(reason)}, falling back to mock data")
          generate_mock_results(query, page)
      end
    else
      generate_mock_results(query, page)
    end
  end

  defp generate_mock_results(query, page) do
    offset = (page - 1) * @per_page

    Enum.map(1..@per_page, fn index ->
      result_number = offset + index
      days_ago = rem(result_number, 30) + 1

      %{
        title: "[Discussion] #{query} - Community Perspectives and Experiences ##{result_number}",
        authors: "u/user#{result_number}",
        source: get_platform_source(result_number),
        date: "#{days_ago} days ago",
        description:
          "Community discussion about #{query}. Users share their insights, experiences, and questions. Includes #{rem(result_number, 50) + 10} comments with valuable perspectives from the community.",
        url: "https://example.com/forum/post-#{result_number}",
        type: :user_content
      }
    end)
  end

  defp get_platform_source(number) do
    sources = [
      "r/programming (Reddit)",
      "Stack Overflow",
      "Hacker News",
      "r/science (Reddit)",
      "Dev.to Community",
      "GitHub Discussions",
      "Discord Server",
      "Discourse Forum"
    ]

    Enum.at(sources, rem(number, length(sources)))
  end

  @doc """
  Fetches user content from Reddit API.
  Requires API key configuration.
  """
  def fetch_from_reddit(_query, _page) do
    # Implementation would go here
    # Example: Make HTTP request to Reddit API
    # url = "https://oauth.reddit.com/search"
    # params = [q: query, limit: @per_page, after: get_after_token(page)]
    []
  end

  @doc """
  Fetches user content from Stack Exchange API.
  """
  def fetch_from_stack_exchange(_query, _page) do
    # Implementation would go here
    # Example: Make HTTP request to Stack Exchange API
    # url = "https://api.stackexchange.com/2.3/search"
    []
  end

  @doc """
  Fetches user content from Hacker News Algolia API.
  Free API with no authentication required.
  """
  def fetch_from_hacker_news(query, page) when is_binary(query) do
    # Hacker News Algolia API uses 0-indexed pages
    algolia_page = page - 1

    url = "https://hn.algolia.com/api/v1/search"

    params = [
      query: query,
      page: algolia_page,
      hitsPerPage: @per_page,
      # Only fetch stories, not comments
      tags: "story"
    ]

    Logger.debug("Hacker News API request: query=#{query}, page=#{page}")

    case Req.get(url, params: params, receive_timeout: 10_000) do
      {:ok, %{status: 200, body: body}} ->
        results = normalize_results(body)
        Logger.info("Hacker News API success: #{length(results)} results")
        {:ok, results}

      {:ok, %{status: status}} ->
        Logger.warning("Hacker News API error: status=#{status}")
        {:error, {:api_error, status}}

      {:error, reason} ->
        Logger.error("Hacker News API request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches user content from Discourse forums.
  """
  def fetch_from_discourse(_query, _page, _forum_url) do
    # Implementation would go here
    # Example: Make HTTP request to Discourse API
    # url = "#{forum_url}/search.json"
    []
  end

  # Private helper functions

  defp use_real_api? do
    Application.get_env(:scholarly_search, :use_real_api, false)
  end

  defp normalize_results(%{"hits" => hits}) when is_list(hits) do
    Enum.map(hits, &normalize_hit/1)
  end

  defp normalize_results(_), do: []

  defp normalize_hit(hit) do
    %{
      title: hit["title"] || "Untitled Post",
      authors: "u/#{hit["author"] || "anonymous"}",
      source: "Hacker News",
      date: format_date(hit["created_at"]),
      description:
        format_text(hit["story_text"] || hit["comment_text"]) || "Discussion on Hacker News.",
      url: build_url(hit),
      type: :user_content,
      metadata: %{
        points: hit["points"] || 0,
        num_comments: hit["num_comments"] || 0,
        object_id: hit["objectID"]
      }
    }
  end

  defp build_url(hit) do
    case hit["objectID"] do
      nil -> "https://news.ycombinator.com"
      id -> "https://news.ycombinator.com/item?id=#{id}"
    end
  end

  defp format_date(nil), do: "Recently"

  defp format_date(date_str) do
    # Algolia returns ISO 8601 format
    # For simplicity, just return the date string
    # In production, you might want to parse and format this
    case DateTime.from_iso8601(date_str) do
      {:ok, datetime, _} ->
        days_ago = DateTime.diff(DateTime.utc_now(), datetime, :day)

        cond do
          days_ago == 0 -> "Today"
          days_ago == 1 -> "Yesterday"
          days_ago < 7 -> "#{days_ago} days ago"
          days_ago < 30 -> "#{div(days_ago, 7)} weeks ago"
          days_ago < 365 -> "#{div(days_ago, 30)} months ago"
          true -> "#{div(days_ago, 365)} years ago"
        end

      _ ->
        "Recently"
    end
  end

  defp format_text(nil), do: nil

  defp format_text(text) when is_binary(text) do
    # Remove HTML tags and limit length
    cleaned =
      text
      |> String.replace(~r/<[^>]*>/, "")
      |> String.trim()

    if String.length(cleaned) > 300 do
      String.slice(cleaned, 0, 297) <> "..."
    else
      cleaned
    end
  end
end
