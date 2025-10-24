defmodule ScholarlySearchWeb.SearchLive do
  use ScholarlySearchWeb, :live_view

  alias ScholarlySearch.Search.{ScholarlyArticles, NewsArticles, UserContent, WebResults}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:search_query, "")
     |> assign(:scholarly_articles, [])
     |> assign(:news_articles, [])
     |> assign(:user_content, [])
     |> assign(:web_results, [])
     |> assign(:scholarly_page, 1)
     |> assign(:news_page, 1)
     |> assign(:user_content_page, 1)
     |> assign(:web_results_page, 1)
     |> assign(:searching, false)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    send(self(), {:perform_search, query})

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:searching, true)
     |> assign(:scholarly_page, 1)
     |> assign(:news_page, 1)
     |> assign(:user_content_page, 1)
     |> assign(:web_results_page, 1)}
  end

  @impl true
  def handle_event("load_more", %{"pane" => pane}, socket) do
    case pane do
      "scholarly" ->
        page = socket.assigns.scholarly_page + 1
        articles = ScholarlyArticles.search(socket.assigns.search_query, page)

        {:noreply,
         socket
         |> assign(:scholarly_articles, socket.assigns.scholarly_articles ++ articles)
         |> assign(:scholarly_page, page)}

      "news" ->
        page = socket.assigns.news_page + 1
        articles = NewsArticles.search(socket.assigns.search_query, page)

        {:noreply,
         socket
         |> assign(:news_articles, socket.assigns.news_articles ++ articles)
         |> assign(:news_page, page)}

      "user" ->
        page = socket.assigns.user_content_page + 1
        content = UserContent.search(socket.assigns.search_query, page)

        {:noreply,
         socket
         |> assign(:user_content, socket.assigns.user_content ++ content)
         |> assign(:user_content_page, page)}

      "web" ->
        page = socket.assigns.web_results_page + 1
        results = WebResults.search(socket.assigns.search_query, page)

        {:noreply,
         socket
         |> assign(:web_results, socket.assigns.web_results ++ results)
         |> assign(:web_results_page, page)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:perform_search, query}, socket) do
    scholarly_articles = ScholarlyArticles.search(query, 1)
    news_articles = NewsArticles.search(query, 1)
    user_content = UserContent.search(query, 1)
    web_results = WebResults.search(query, 1)

    {:noreply,
     socket
     |> assign(:scholarly_articles, scholarly_articles)
     |> assign(:news_articles, news_articles)
     |> assign(:user_content, user_content)
     |> assign(:web_results, web_results)
     |> assign(:searching, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-gray-50 via-white to-gray-100">
      <!-- Swiss-Inspired Header -->
      <div class="sticky top-0 z-20 bg-white/95 backdrop-blur-sm border-b-2 border-black shadow-lg">
        <div class="max-w-[1600px] mx-auto px-8 py-6">
          <!-- Logo/Title -->
          <div class="mb-4">
            <h1 class="text-3xl font-bold tracking-tight swiss-title flex items-center gap-3">
              <span class="inline-block w-2 h-8 bg-[#fad608]"></span>
              <span class="text-gray-900">ScholarlySearch</span>
            </h1>
            <p class="text-sm text-gray-600 ml-5 mt-1 swiss-mono">Unified knowledge discovery</p>
          </div>
          
    <!-- Search Form -->
          <form phx-submit="search" class="flex gap-3">
            <div class="flex-1 relative">
              <input
                type="text"
                name="query"
                value={@search_query}
                placeholder="Search across scholarly articles, news, forums, and web..."
                class="search-input w-full px-6 py-4 text-lg border-2 border-gray-900 focus:border-[#fad608] focus:outline-none transition-all duration-200"
                autofocus
              />
              <%= if @searching do %>
                <div class="absolute right-4 top-1/2 -translate-y-1/2">
                  <div class="w-5 h-5 border-2 border-gray-300 border-t-[#fad608] rounded-full animate-spin">
                  </div>
                </div>
              <% end %>
            </div>
            <button
              type="submit"
              class="swiss-button px-8 py-4 bg-gray-900 text-white font-semibold hover:bg-[#fad608] hover:text-black border-2 border-gray-900 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={@searching}
            >
              {if @searching, do: "Searching...", else: "Search"}
            </button>
          </form>
        </div>
      </div>
      
    <!-- Four-Pane Grid Interface -->
      <div class="max-w-[1600px] mx-auto p-6">
        <div class="grid grid-cols-2 gap-6 h-[calc(100vh-220px)]">
          <!-- Top-Left: Scholarly Articles -->
          <div class="bg-white border-2 border-gray-900 shadow-lg overflow-hidden flex flex-col">
            <div class="pane-header px-6 py-4 bg-gray-900 text-white border-b-4 border-[#fad608]">
              <div class="flex items-center justify-between">
                <h2 class="text-xl font-bold swiss-title flex items-center gap-2">
                  <span class="text-2xl">📚</span>
                  <span>Scholarly</span>
                </h2>
                <span class="swiss-mono text-xs opacity-75">
                  {length(@scholarly_articles)} results
                </span>
              </div>
            </div>
            <div
              class="flex-1 overflow-y-auto p-6 space-y-3 smooth-scroll"
              id="scholarly-pane"
              phx-update="append"
            >
              <%= if @scholarly_articles == [] and @search_query != "" and not @searching do %>
                <p class="text-gray-500 text-center py-12 swiss-mono">No scholarly articles found</p>
              <% else %>
                <%= for {article, index} <- Enum.with_index(@scholarly_articles) do %>
                  <.paper_card article={article} index={index} color="scholarly" />
                <% end %>
              <% end %>
              <%= if length(@scholarly_articles) > 0 do %>
                <button
                  phx-click="load_more"
                  phx-value-pane="scholarly"
                  class="w-full py-3 mt-4 bg-white border-2 border-gray-900 hover:bg-gray-900 hover:text-white font-semibold transition-all duration-300 swiss-mono text-sm"
                >
                  Load More ↓
                </button>
              <% end %>
            </div>
          </div>
          
    <!-- Top-Right: News & Current Events -->
          <div class="bg-white border-2 border-gray-900 shadow-lg overflow-hidden flex flex-col">
            <div class="pane-header px-6 py-4 bg-gray-900 text-white border-b-4 border-[#e3001b]">
              <div class="flex items-center justify-between">
                <h2 class="text-xl font-bold swiss-title flex items-center gap-2">
                  <span class="text-2xl">📰</span>
                  <span>News</span>
                </h2>
                <span class="swiss-mono text-xs opacity-75">{length(@news_articles)} results</span>
              </div>
            </div>
            <div
              class="flex-1 overflow-y-auto p-6 space-y-3 smooth-scroll"
              id="news-pane"
              phx-update="append"
            >
              <%= if @news_articles == [] and @search_query != "" and not @searching do %>
                <p class="text-gray-500 text-center py-12 swiss-mono">No news articles found</p>
              <% else %>
                <%= for {article, index} <- Enum.with_index(@news_articles) do %>
                  <.paper_card article={article} index={index} color="news" />
                <% end %>
              <% end %>
              <%= if length(@news_articles) > 0 do %>
                <button
                  phx-click="load_more"
                  phx-value-pane="news"
                  class="w-full py-3 mt-4 bg-white border-2 border-gray-900 hover:bg-gray-900 hover:text-white font-semibold transition-all duration-300 swiss-mono text-sm"
                >
                  Load More ↓
                </button>
              <% end %>
            </div>
          </div>
          
    <!-- Bottom-Left: User Generated Content -->
          <div class="bg-white border-2 border-gray-900 shadow-lg overflow-hidden flex flex-col">
            <div class="pane-header px-6 py-4 bg-gray-900 text-white border-b-4 border-[#0066cc]">
              <div class="flex items-center justify-between">
                <h2 class="text-xl font-bold swiss-title flex items-center gap-2">
                  <span class="text-2xl">💬</span>
                  <span>Forums</span>
                </h2>
                <span class="swiss-mono text-xs opacity-75">{length(@user_content)} results</span>
              </div>
            </div>
            <div
              class="flex-1 overflow-y-auto p-6 space-y-3 smooth-scroll"
              id="user-content-pane"
              phx-update="append"
            >
              <%= if @user_content == [] and @search_query != "" and not @searching do %>
                <p class="text-gray-500 text-center py-12 swiss-mono">No forum posts found</p>
              <% else %>
                <%= for {content, index} <- Enum.with_index(@user_content) do %>
                  <.paper_card article={content} index={index} color="forums" />
                <% end %>
              <% end %>
              <%= if length(@user_content) > 0 do %>
                <button
                  phx-click="load_more"
                  phx-value-pane="user"
                  class="w-full py-3 mt-4 bg-white border-2 border-gray-900 hover:bg-gray-900 hover:text-white font-semibold transition-all duration-300 swiss-mono text-sm"
                >
                  Load More ↓
                </button>
              <% end %>
            </div>
          </div>
          
    <!-- Bottom-Right: Web Search Results -->
          <div class="bg-white border-2 border-gray-900 shadow-lg overflow-hidden flex flex-col">
            <div class="pane-header px-6 py-4 bg-gray-900 text-white border-b-4 border-[#fad608]">
              <div class="flex items-center justify-between">
                <h2 class="text-xl font-bold swiss-title flex items-center gap-2">
                  <span class="text-2xl">🌐</span>
                  <span>Web</span>
                </h2>
                <span class="swiss-mono text-xs opacity-75">{length(@web_results)} results</span>
              </div>
            </div>
            <div
              class="flex-1 overflow-y-auto p-6 space-y-3 smooth-scroll"
              id="web-results-pane"
              phx-update="append"
            >
              <%= if @web_results == [] and @search_query != "" and not @searching do %>
                <p class="text-gray-500 text-center py-12 swiss-mono">No web results found</p>
              <% else %>
                <%= for {result, index} <- Enum.with_index(@web_results) do %>
                  <.paper_card article={result} index={index} color="web" />
                <% end %>
              <% end %>
              <%= if length(@web_results) > 0 do %>
                <button
                  phx-click="load_more"
                  phx-value-pane="web"
                  class="w-full py-3 mt-4 bg-white border-2 border-gray-900 hover:bg-gray-900 hover:text-white font-semibold transition-all duration-300 swiss-mono text-sm"
                >
                  Load More ↓
                </button>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Component for paper-style card with Swiss design
  attr :article, :map, required: true
  attr :index, :integer, required: true
  attr :color, :string, default: "scholarly"

  def paper_card(assigns) do
    accent_color =
      case assigns.color do
        "scholarly" -> "#fad608"
        "news" -> "#e3001b"
        "forums" -> "#0066cc"
        "web" -> "#fad608"
        _ -> "#fad608"
      end

    assigns = assign(assigns, :accent_color, accent_color)

    ~H"""
    <div class="result-card paper-stack bg-white border-l-4 border-gray-200 p-5 hover:border-l-[6px] group">
      <a href={@article.url} target="_blank" class="block">
        <h3 class="text-lg font-bold text-gray-900 group-hover:text-gray-900 leading-tight mb-2 swiss-title">
          {@article.title}
        </h3>

        <div class="flex flex-wrap gap-3 mb-3">
          <%= if Map.get(@article, :authors) do %>
            <div class="flex items-center gap-1">
              <span class="text-xs font-semibold text-gray-500 swiss-mono">BY</span>
              <span class="text-sm text-gray-700">{@article.authors}</span>
            </div>
          <% end %>

          <%= if Map.get(@article, :source) do %>
            <div class="flex items-center gap-1">
              <span class="text-xs font-semibold text-gray-500 swiss-mono">FROM</span>
              <span class="text-sm text-gray-700 font-medium">{@article.source}</span>
            </div>
          <% end %>

          <%= if Map.get(@article, :date) do %>
            <div class="flex items-center gap-1">
              <span class="text-xs font-semibold text-gray-500 swiss-mono">DATE</span>
              <span class="text-sm text-gray-600 swiss-mono">{@article.date}</span>
            </div>
          <% end %>
        </div>

        <p class="text-sm text-gray-700 leading-relaxed line-clamp-3">
          {@article.description}
        </p>

        <div class="mt-3 pt-3 border-t border-gray-100">
          <span class="inline-flex items-center gap-2 text-xs font-semibold swiss-mono group-hover:gap-3 transition-all">
            <span style={"color: #{@accent_color}"}>READ MORE</span>
            <span style={"color: #{@accent_color}"}>→</span>
          </span>
        </div>
      </a>
    </div>
    """
  end
end
