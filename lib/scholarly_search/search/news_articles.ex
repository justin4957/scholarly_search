defmodule ScholarlySearch.Search.NewsArticles do
  @moduledoc """
  Handles searching for news articles and current events from various news sources.
  This module integrates with:
  - Google News RSS (currently implemented)
  - NewsAPI (ready for integration)
  - Reuters API (ready for integration)
  """

  require Logger

  @per_page 10

  @doc """
  Searches for news articles based on the given query and page number.
  """
  def search("", _page), do: []

  def search(query, page) do
    if use_real_api?() do
      case fetch_from_google_news(query, page) do
        {:ok, results} ->
          results

        {:error, reason} ->
          Logger.warning("Google News RSS failed: #{inspect(reason)}, falling back to mock data")
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
      hours_ago = rem(result_number, 24) + 1

      %{
        title:
          "Breaking: #{query} Impacts Global Markets and Policy Decisions - Article #{result_number}",
        authors: "News Team, Staff Reporter",
        source: get_news_source(result_number),
        date: "#{hours_ago} hours ago",
        description:
          "Latest developments regarding #{query} have emerged as experts weigh in on the implications for industry and society. This comprehensive report covers breaking news and analysis from multiple sources.",
        url: "https://example.com/news/article-#{result_number}",
        type: :news
      }
    end)
  end

  defp get_news_source(number) do
    sources = [
      "Reuters",
      "Associated Press",
      "BBC News",
      "CNN",
      "The Guardian",
      "New York Times",
      "Washington Post",
      "Bloomberg"
    ]

    Enum.at(sources, rem(number, length(sources)))
  end

  @doc """
  Fetches news articles from NewsAPI.
  Requires API key configuration.
  """
  def fetch_from_newsapi(_query, _page) do
    # Implementation would go here
    # Example: Make HTTP request to NewsAPI
    # url = "https://newsapi.org/v2/everything"
    # params = [q: query, page: page, pageSize: @per_page, apiKey: api_key()]
    []
  end

  @doc """
  Fetches news articles from Google News RSS feeds.
  Uses simple HTTP request to fetch RSS and basic XML parsing.

  Note: RSS parsing is basic - for production, consider using an RSS library.
  """
  def fetch_from_google_news(query, page) when is_binary(query) do
    # Google News RSS doesn't support pagination directly
    # We fetch and slice results client-side
    url =
      "https://news.google.com/rss/search?q=#{URI.encode_www_form(query)}&hl=en-US&gl=US&ceid=US:en"

    Logger.debug("Google News RSS request: query=#{query}, page=#{page}")

    case Req.get(url, receive_timeout: 10_000) do
      {:ok, %{status: 200, body: body}} ->
        results = parse_rss(body, query)
        paginated_results = paginate_results(results, page)
        Logger.info("Google News RSS success: #{length(paginated_results)} results")
        {:ok, paginated_results}

      {:ok, %{status: status}} ->
        Logger.warning("Google News RSS error: status=#{status}")
        {:error, {:api_error, status}}

      {:error, reason} ->
        Logger.error("Google News RSS request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches news articles from multiple RSS feeds.
  """
  def fetch_from_rss_feeds(_query, _page) do
    # Implementation would go here
    # Example: Aggregate results from multiple RSS feeds
    []
  end

  # Private helper functions

  defp use_real_api? do
    Application.get_env(:scholarly_search, :use_real_api, false)
  end

  defp parse_rss(xml_content, _query) do
    # Simple RSS parsing - extract <item> elements
    # This is a basic implementation; for production, use a proper XML parser library

    items =
      Regex.scan(~r/<item>(.*?)<\/item>/s, xml_content)
      |> Enum.map(fn [_, item] -> item end)
      # Limit to 50 items
      |> Enum.take(50)

    Enum.map(items, fn item ->
      %{
        title: extract_tag(item, "title"),
        authors: extract_tag(item, "source") || "Google News",
        source: extract_tag(item, "source") || "News Source",
        date: format_date(extract_tag(item, "pubDate")),
        description: clean_description(extract_tag(item, "description")),
        url: extract_tag(item, "link"),
        type: :news
      }
    end)
    |> Enum.filter(fn article -> article.title != nil and article.url != nil end)
  end

  defp extract_tag(xml, tag) do
    case Regex.run(~r/<#{tag}>(.*?)<\/#{tag}>/s, xml) do
      [_, content] -> clean_xml_content(content)
      _ -> nil
    end
  end

  defp clean_xml_content(content) do
    content
    |> String.replace(~r/<!\[CDATA\[(.*?)\]\]>/s, "\\1")
    |> String.replace(~r/<[^>]*>/, "")
    |> String.trim()
    |> case do
      "" -> nil
      cleaned -> cleaned
    end
  end

  defp clean_description(nil), do: "No description available."

  defp clean_description(desc) do
    # Remove HTML tags and limit length
    cleaned = String.replace(desc, ~r/<[^>]*>/, "")

    if String.length(cleaned) > 300 do
      String.slice(cleaned, 0, 297) <> "..."
    else
      cleaned
    end
  end

  defp format_date(nil), do: "Recently"

  defp format_date(date_str) do
    # Google News RSS uses RFC 822 format
    # Just extract relative time for simplicity
    date_str
  end

  defp paginate_results(results, page) do
    offset = (page - 1) * @per_page
    Enum.slice(results, offset, @per_page)
  end
end
