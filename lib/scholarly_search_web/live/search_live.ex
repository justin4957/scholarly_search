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
    <div class="min-h-screen bg-gray-50">
      <!-- Search Bar -->
      <div class="sticky top-0 z-10 bg-white border-b border-gray-200 shadow-sm">
        <div class="max-w-7xl mx-auto px-4 py-4">
          <form phx-submit="search" class="flex gap-2">
            <input
              type="text"
              name="query"
              value={@search_query}
              placeholder="Search across scholarly articles, news, forums, and web..."
              class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              autofocus
            />
            <button
              type="submit"
              class="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
              disabled={@searching}
            >
              {if @searching, do: "Searching...", else: "Search"}
            </button>
          </form>
        </div>
      </div>
      
    <!-- Four-Pane Interface -->
      <div class="max-w-7xl mx-auto p-4">
        <div class="grid grid-cols-2 gap-4 h-[calc(100vh-120px)]">
          <!-- Top-Left: Scholarly Articles -->
          <div class="bg-white rounded-lg shadow-md overflow-hidden flex flex-col">
            <div class="px-4 py-3 bg-gradient-to-r from-purple-600 to-purple-700 text-white">
              <h2 class="text-lg font-semibold">📚 Scholarly Articles</h2>
            </div>
            <div class="flex-1 overflow-y-auto p-4 space-y-2" id="scholarly-pane">
              <%= if @scholarly_articles == [] and @search_query != "" and not @searching do %>
                <p class="text-gray-500 text-center py-8">No scholarly articles found</p>
              <% else %>
                <%= for {article, index} <- Enum.with_index(@scholarly_articles) do %>
                  <.paper_card article={article} index={index} />
                <% end %>
              <% end %>
              <%= if length(@scholarly_articles) > 0 do %>
                <button
                  phx-click="load_more"
                  phx-value-pane="scholarly"
                  class="w-full py-2 text-purple-600 hover:bg-purple-50 rounded-lg border border-purple-200"
                >
                  Load More
                </button>
              <% end %>
            </div>
          </div>
          
    <!-- Top-Right: News & Current Events -->
          <div class="bg-white rounded-lg shadow-md overflow-hidden flex flex-col">
            <div class="px-4 py-3 bg-gradient-to-r from-red-600 to-red-700 text-white">
              <h2 class="text-lg font-semibold">📰 News & Current Events</h2>
            </div>
            <div class="flex-1 overflow-y-auto p-4 space-y-2" id="news-pane">
              <%= if @news_articles == [] and @search_query != "" and not @searching do %>
                <p class="text-gray-500 text-center py-8">No news articles found</p>
              <% else %>
                <%= for {article, index} <- Enum.with_index(@news_articles) do %>
                  <.paper_card article={article} index={index} />
                <% end %>
              <% end %>
              <%= if length(@news_articles) > 0 do %>
                <button
                  phx-click="load_more"
                  phx-value-pane="news"
                  class="w-full py-2 text-red-600 hover:bg-red-50 rounded-lg border border-red-200"
                >
                  Load More
                </button>
              <% end %>
            </div>
          </div>
          
    <!-- Bottom-Left: User Generated Content -->
          <div class="bg-white rounded-lg shadow-md overflow-hidden flex flex-col">
            <div class="px-4 py-3 bg-gradient-to-r from-green-600 to-green-700 text-white">
              <h2 class="text-lg font-semibold">💬 Forums & Community</h2>
            </div>
            <div class="flex-1 overflow-y-auto p-4 space-y-2" id="user-content-pane">
              <%= if @user_content == [] and @search_query != "" and not @searching do %>
                <p class="text-gray-500 text-center py-8">No forum posts found</p>
              <% else %>
                <%= for {content, index} <- Enum.with_index(@user_content) do %>
                  <.paper_card article={content} index={index} />
                <% end %>
              <% end %>
              <%= if length(@user_content) > 0 do %>
                <button
                  phx-click="load_more"
                  phx-value-pane="user"
                  class="w-full py-2 text-green-600 hover:bg-green-50 rounded-lg border border-green-200"
                >
                  Load More
                </button>
              <% end %>
            </div>
          </div>
          
    <!-- Bottom-Right: Web Search Results -->
          <div class="bg-white rounded-lg shadow-md overflow-hidden flex flex-col">
            <div class="px-4 py-3 bg-gradient-to-r from-blue-600 to-blue-700 text-white">
              <h2 class="text-lg font-semibold">🌐 Web Results</h2>
            </div>
            <div class="flex-1 overflow-y-auto p-4 space-y-2" id="web-results-pane">
              <%= if @web_results == [] and @search_query != "" and not @searching do %>
                <p class="text-gray-500 text-center py-8">No web results found</p>
              <% else %>
                <%= for {result, index} <- Enum.with_index(@web_results) do %>
                  <.paper_card article={result} index={index} />
                <% end %>
              <% end %>
              <%= if length(@web_results) > 0 do %>
                <button
                  phx-click="load_more"
                  phx-value-pane="web"
                  class="w-full py-2 text-blue-600 hover:bg-blue-50 rounded-lg border border-blue-200"
                >
                  Load More
                </button>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Component for paper-style card
  attr :article, :map, required: true
  attr :index, :integer, required: true

  def paper_card(assigns) do
    ~H"""
    <div
      class="bg-white border border-gray-200 rounded-lg shadow-sm hover:shadow-md transition-shadow p-4 cursor-pointer"
      style={"transform: translateX(#{@index * 2}px) translateY(#{@index * -1}px);"}
    >
      <a href={@article.url} target="_blank" class="block">
        <h3 class="font-semibold text-gray-900 hover:text-blue-600 line-clamp-2">
          {@article.title}
        </h3>
        <%= if Map.get(@article, :authors) do %>
          <p class="text-sm text-gray-600 mt-1">
            {@article.authors}
          </p>
        <% end %>
        <%= if Map.get(@article, :source) do %>
          <p class="text-sm text-gray-500 mt-1">
            {@article.source}
          </p>
        <% end %>
        <%= if Map.get(@article, :date) do %>
          <p class="text-xs text-gray-400 mt-1">
            {@article.date}
          </p>
        <% end %>
        <p class="text-sm text-gray-700 mt-2 line-clamp-3">
          {@article.description}
        </p>
      </a>
    </div>
    """
  end
end
