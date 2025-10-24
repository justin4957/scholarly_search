defmodule ScholarlySearch.Search.ScholarlyArticles do
  @moduledoc """
  Handles searching for scholarly journal articles from various academic sources.
  This module can be extended to integrate with APIs like:
  - Semantic Scholar API
  - CrossRef API
  - PubMed API
  - arXiv API
  - Google Scholar (via scraping or unofficial APIs)
  """

  require Logger

  @per_page 10
  @base_url "https://api.semanticscholar.org/graph/v1"

  @doc """
  Searches for scholarly articles based on the given query and page number.
  """
  def search("", _page), do: []

  def search(query, page) do
    if use_real_api?() do
      case fetch_from_semantic_scholar(query, page) do
        {:ok, results} ->
          results

        {:error, reason} ->
          Logger.warning(
            "Semantic Scholar API failed: #{inspect(reason)}, falling back to mock data"
          )

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

      %{
        title: "#{query}: A Comprehensive Study of Academic Research (Part #{result_number})",
        authors: "Dr. Jane Smith, Prof. John Doe, Dr. Alice Johnson",
        source:
          "Journal of Advanced Studies, Vol. #{result_number}, Issue #{rem(result_number, 4) + 1}",
        date: "2024-#{rem(result_number, 12) + 1}-#{rem(result_number, 28) + 1}",
        description:
          "This peer-reviewed article explores various aspects of #{query} through rigorous methodology and empirical analysis. The study presents novel findings that contribute to the existing body of knowledge in the field.",
        url: "https://example.com/scholarly/article-#{result_number}",
        type: :scholarly
      }
    end)
  end

  @doc """
  Fetches scholarly articles from Semantic Scholar API.
  Requires API key configuration (optional - free tier available without key).

  ## Options
  - `:page` - Page number (default: 1)
  - `:per_page` - Results per page (default: 10, max: 100)

  ## Returns
  - `{:ok, [result]}` on success
  - `{:error, reason}` on failure
  """
  def fetch_from_semantic_scholar(query, page) when is_binary(query) do
    offset = (page - 1) * @per_page

    params = [
      query: query,
      offset: offset,
      limit: @per_page,
      fields: "paperId,title,abstract,authors,year,citationCount,url,venue,publicationDate"
    ]

    headers = build_headers()
    url = "#{@base_url}/paper/search"

    Logger.debug("Semantic Scholar API request: query=#{query}, page=#{page}, offset=#{offset}")

    case Req.get(url, params: params, headers: headers, receive_timeout: 10_000) do
      {:ok, %{status: 200, body: body}} ->
        results = normalize_results(body)
        Logger.info("Semantic Scholar API success: #{length(results)} results")
        {:ok, results}

      {:ok, %{status: 429}} ->
        Logger.warning("Semantic Scholar API rate limit exceeded")
        {:error, :rate_limit_exceeded}

      {:ok, %{status: status, body: body}} ->
        Logger.warning("Semantic Scholar API error: status=#{status}, body=#{inspect(body)}")
        {:error, {:api_error, status}}

      {:error, reason} ->
        Logger.error("Semantic Scholar API request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches scholarly articles from CrossRef API.
  """
  def fetch_from_crossref(_query, _page) do
    # Implementation would go here
    # Example: Make HTTP request to CrossRef API
    # url = "https://api.crossref.org/works"
    []
  end

  @doc """
  Fetches scholarly articles from PubMed API.
  """
  def fetch_from_pubmed(_query, _page) do
    # Implementation would go here
    # Example: Make HTTP request to PubMed API
    # url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
    []
  end

  @doc """
  Fetches scholarly articles from arXiv API.
  """
  def fetch_from_arxiv(_query, _page) do
    # Implementation would go here
    # Example: Make HTTP request to arXiv API
    # url = "http://export.arxiv.org/api/query"
    []
  end

  # Private helper functions

  defp use_real_api? do
    Application.get_env(:scholarly_search, :use_real_api, false)
  end

  defp build_headers do
    base_headers = [{"User-Agent", "ScholarlySearch/1.0"}]

    case api_key() do
      nil ->
        base_headers

      key ->
        [{"x-api-key", key} | base_headers]
    end
  end

  defp api_key do
    Application.get_env(:scholarly_search, :semantic_scholar_api_key)
  end

  defp normalize_results(%{"data" => papers}) when is_list(papers) do
    Enum.map(papers, &normalize_paper/1)
  end

  defp normalize_results(_), do: []

  defp normalize_paper(paper) do
    %{
      title: paper["title"] || "Untitled",
      authors: format_authors(paper["authors"]),
      source: format_source(paper),
      date: format_date(paper["publicationDate"], paper["year"]),
      description: format_abstract(paper["abstract"]),
      url: paper["url"] || "https://www.semanticscholar.org/paper/#{paper["paperId"]}",
      type: :scholarly,
      metadata: %{
        paper_id: paper["paperId"],
        citation_count: paper["citationCount"] || 0,
        year: paper["year"],
        venue: paper["venue"]
      }
    }
  end

  defp format_authors(authors) when is_list(authors) do
    authors
    |> Enum.take(3)
    |> Enum.map(& &1["name"])
    |> Enum.join(", ")
    |> case do
      "" -> "Unknown"
      names -> names
    end
  end

  defp format_authors(_), do: "Unknown"

  defp format_source(paper) do
    venue = paper["venue"]
    year = paper["year"]

    cond do
      venue && year -> "#{venue} (#{year})"
      venue -> venue
      year -> "Publication #{year}"
      true -> "Semantic Scholar"
    end
  end

  defp format_date(date, _year) when is_binary(date) do
    date
  end

  defp format_date(_, year) when is_integer(year) do
    "#{year}"
  end

  defp format_date(_, _), do: "Date unknown"

  defp format_abstract(nil), do: "No abstract available."

  defp format_abstract(abstract) when is_binary(abstract) do
    if String.length(abstract) > 300 do
      String.slice(abstract, 0, 297) <> "..."
    else
      abstract
    end
  end
end
