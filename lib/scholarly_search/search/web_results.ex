defmodule ScholarlySearch.Search.WebResults do
  @moduledoc """
  Handles searching for general web results from search engines and web sources.
  This module integrates with:
  - Brave Search API (currently implemented - requires API key)
  - Google Custom Search API (ready for integration)
  - Bing Search API (ready for integration)
  """

  require Logger

  @per_page 10

  @doc """
  Searches for web results based on the given query and page number.
  """
  def search("", _page), do: []

  def search(query, page) do
    if use_real_api?() and brave_api_key() do
      case fetch_from_brave_search(query, page) do
        {:ok, results} ->
          results

        {:error, reason} ->
          Logger.warning("Brave Search API failed: #{inspect(reason)}, falling back to mock data")
          generate_mock_results(query, page)
      end
    else
      if use_real_api?() and !brave_api_key() do
        Logger.warning("Brave Search API key not configured, using mock data")
      end

      generate_mock_results(query, page)
    end
  end

  defp generate_mock_results(query, page) do
    offset = (page - 1) * @per_page

    Enum.map(1..@per_page, fn index ->
      result_number = offset + index

      %{
        title: "#{query} - Complete Guide and Resources ##{result_number}",
        authors: nil,
        source: get_domain(result_number),
        date: nil,
        description:
          "Comprehensive information about #{query} including tutorials, guides, documentation, and practical examples. This resource provides detailed coverage of key concepts and best practices.",
        url:
          "https://example#{result_number}.com/#{query |> String.downcase() |> String.replace(" ", "-")}",
        type: :web
      }
    end)
  end

  defp get_domain(number) do
    domains = [
      "wikipedia.org",
      "medium.com",
      "docs.example.com",
      "tutorial.site",
      "blog.tech",
      "academy.edu",
      "resources.dev",
      "guide.io"
    ]

    Enum.at(domains, rem(number, length(domains)))
  end

  @doc """
  Fetches web results from Google Custom Search API.
  Requires API key and Search Engine ID configuration.
  """
  def fetch_from_google_custom_search(_query, _page) do
    # Implementation would go here
    # Example: Make HTTP request to Google Custom Search API
    # url = "https://www.googleapis.com/customsearch/v1"
    # params = [key: api_key(), cx: search_engine_id(), q: query, start: (page - 1) * @per_page + 1]
    []
  end

  @doc """
  Fetches web results from Bing Search API.
  Requires API key configuration.
  """
  def fetch_from_bing_search(_query, _page) do
    # Implementation would go here
    # Example: Make HTTP request to Bing Search API
    # url = "https://api.bing.microsoft.com/v7.0/search"
    []
  end

  @doc """
  Fetches web results from DuckDuckGo API.
  """
  def fetch_from_duckduckgo(_query, _page) do
    # Implementation would go here
    # Example: Make HTTP request to DuckDuckGo API
    # url = "https://api.duckduckgo.com/"
    []
  end

  @doc """
  Fetches web results from Brave Search API.
  Requires API key configuration.

  Get your free API key at: https://brave.com/search/api/
  Free tier: 2,000 queries per month
  """
  def fetch_from_brave_search(query, page) when is_binary(query) do
    api_key = brave_api_key()

    if !api_key do
      {:error, :api_key_missing}
    else
      do_search(query, page, api_key)
    end
  end

  defp do_search(query, page, api_key) do
    # Brave Search API uses 0-indexed offset
    offset = (page - 1) * @per_page

    url = "https://api.search.brave.com/res/v1/web/search"

    params = [
      q: query,
      count: @per_page,
      offset: offset,
      search_lang: "en",
      result_filter: "web"
    ]

    headers = [
      {"X-Subscription-Token", api_key},
      {"Accept", "application/json"}
    ]

    Logger.debug("Brave Search API request: query=#{query}, page=#{page}, offset=#{offset}")

    case Req.get(url, params: params, headers: headers, receive_timeout: 10_000) do
      {:ok, %{status: 200, body: body}} ->
        results = normalize_results(body)
        Logger.info("Brave Search API success: #{length(results)} results")
        {:ok, results}

      {:ok, %{status: 401}} ->
        Logger.error("Brave Search API: Invalid API key")
        {:error, :invalid_api_key}

      {:ok, %{status: 429}} ->
        Logger.warning("Brave Search API: Rate limit exceeded")
        {:error, :rate_limit_exceeded}

      {:ok, %{status: status, body: body}} ->
        Logger.warning("Brave Search API error: status=#{status}, body=#{inspect(body)}")
        {:error, {:api_error, status}}

      {:error, reason} ->
        Logger.error("Brave Search API request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private helper functions

  defp use_real_api? do
    Application.get_env(:scholarly_search, :use_real_api, false)
  end

  defp brave_api_key do
    Application.get_env(:scholarly_search, :brave_api_key)
  end

  defp normalize_results(%{"web" => %{"results" => results}}) when is_list(results) do
    Enum.map(results, &normalize_result/1)
  end

  defp normalize_results(_), do: []

  defp normalize_result(result) do
    %{
      title: result["title"] || "Untitled",
      authors: nil,
      source: extract_domain(result["url"]),
      date: format_date(result["age"]),
      description: result["description"] || "No description available.",
      url: result["url"],
      type: :web,
      metadata: %{
        language: result["language"],
        page_age: result["age"],
        family_friendly: result["family_friendly"]
      }
    }
  end

  defp extract_domain(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) -> host
      _ -> "Unknown"
    end
  end

  defp extract_domain(_), do: "Unknown"

  defp format_date(nil), do: nil

  defp format_date(age) when is_binary(age) do
    # Brave returns age like "2024-01-15T10:30:00"
    case DateTime.from_iso8601(age) do
      {:ok, datetime, _} ->
        Date.to_string(DateTime.to_date(datetime))

      _ ->
        nil
    end
  end

  defp format_date(_), do: nil
end
