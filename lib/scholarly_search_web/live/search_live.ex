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
     |> assign(:searching, false)
     |> assign(:scholarly_loading, false)
     |> assign(:news_loading, false)
     |> assign(:user_content_loading, false)
     |> assign(:web_results_loading, false)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    # Clear previous results and set all panes to loading
    socket =
      socket
      |> assign(:search_query, query)
      |> assign(:searching, true)
      |> assign(:scholarly_articles, [])
      |> assign(:news_articles, [])
      |> assign(:user_content, [])
      |> assign(:web_results, [])
      |> assign(:scholarly_page, 1)
      |> assign(:news_page, 1)
      |> assign(:user_content_page, 1)
      |> assign(:web_results_page, 1)
      |> assign(:scholarly_loading, true)
      |> assign(:news_loading, true)
      |> assign(:user_content_loading, true)
      |> assign(:web_results_loading, true)

    # Trigger async searches for each pane
    send(self(), {:search_scholarly, query})
    send(self(), {:search_news, query})
    send(self(), {:search_user_content, query})
    send(self(), {:search_web, query})

    {:noreply, socket}
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
  def handle_info({:search_scholarly, query}, socket) do
    scholarly_articles = ScholarlyArticles.search(query, 1)

    {:noreply,
     socket
     |> assign(:scholarly_articles, scholarly_articles)
     |> assign(:scholarly_loading, false)
     |> check_all_loaded()}
  end

  @impl true
  def handle_info({:search_news, query}, socket) do
    news_articles = NewsArticles.search(query, 1)

    {:noreply,
     socket
     |> assign(:news_articles, news_articles)
     |> assign(:news_loading, false)
     |> check_all_loaded()}
  end

  @impl true
  def handle_info({:search_user_content, query}, socket) do
    user_content = UserContent.search(query, 1)

    {:noreply,
     socket
     |> assign(:user_content, user_content)
     |> assign(:user_content_loading, false)
     |> check_all_loaded()}
  end

  @impl true
  def handle_info({:search_web, query}, socket) do
    web_results = WebResults.search(query, 1)

    {:noreply,
     socket
     |> assign(:web_results, web_results)
     |> assign(:web_results_loading, false)
     |> check_all_loaded()}
  end

  defp check_all_loaded(socket) do
    all_loaded =
      !socket.assigns.scholarly_loading &&
        !socket.assigns.news_loading &&
        !socket.assigns.user_content_loading &&
        !socket.assigns.web_results_loading

    if all_loaded do
      assign(socket, :searching, false)
    else
      socket
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white">
      <!-- Minimal Header -->
      <div class="sticky top-0 z-20 bg-white/95 backdrop-blur-sm border-b border-gray-200">
        <div class="max-w-[1600px] mx-auto px-6 py-4">
          <div class="flex items-center gap-4">
            <!-- Logo Mark -->
            <div class="flex items-center gap-2">
              <span class="inline-block w-1 h-6 bg-[#fad608]"></span>
              <h1 class="text-lg font-bold tracking-tight text-gray-900 swiss-title">
                ScholarlySearch
              </h1>
            </div>
            
    <!-- Search Form -->
            <form phx-submit="search" class="flex-1 flex gap-2">
              <div class="flex-1 relative">
                <input
                  type="text"
                  name="query"
                  value={@search_query}
                  placeholder="Search across scholarly articles, news, forums, and web..."
                  class="search-input w-full px-4 py-2 text-sm border border-gray-300 focus:border-gray-900 focus:outline-none transition-all duration-200"
                  autofocus
                />
                <%= if @searching do %>
                  <div class="absolute right-3 top-1/2 -translate-y-1/2">
                    <div class="w-4 h-4 border-2 border-gray-300 border-t-[#fad608] rounded-full animate-spin">
                    </div>
                  </div>
                <% end %>
              </div>
              <button
                type="submit"
                class="swiss-button px-6 py-2 bg-gray-900 text-white text-sm font-semibold hover:bg-[#fad608] hover:text-black border border-gray-900 transition-all duration-300 disabled:opacity-50"
                disabled={@searching}
              >
                {if @searching, do: "Searching", else: "Search"}
              </button>
            </form>
          </div>
        </div>
      </div>
      
    <!-- Four-Pane Grid Interface -->
      <div class="max-w-[1600px] mx-auto p-4">
        <div class="grid grid-cols-2 gap-4 h-[calc(100vh-100px)]">
          <!-- Scholarly Articles -->
          <div class="border border-gray-200 overflow-hidden flex flex-col bg-white">
            <div class="px-4 py-2 border-b border-gray-200 bg-gray-50">
              <div class="flex items-center justify-between">
                <h2 class="text-sm font-semibold text-gray-900 swiss-mono">SCHOLARLY</h2>
                <span class="text-xs text-gray-500 swiss-mono">{length(@scholarly_articles)}</span>
              </div>
            </div>
            <div class="flex-1 overflow-y-auto p-4 space-y-3 smooth-scroll" id="scholarly-pane">
              <%= if @scholarly_loading do %>
                <.skeleton_loader />
              <% else %>
                <%= if @scholarly_articles == [] and @search_query != "" do %>
                  <p class="text-gray-400 text-center py-12 text-sm swiss-mono">No results found</p>
                <% else %>
                  <%= for {article, index} <- Enum.with_index(@scholarly_articles) do %>
                    <.paper_card article={article} index={index} color="scholarly" />
                  <% end %>
                <% end %>
                <%= if length(@scholarly_articles) > 0 do %>
                  <button
                    phx-click="load_more"
                    phx-value-pane="scholarly"
                    class="w-full py-2 mt-2 bg-white border border-gray-300 hover:border-gray-900 hover:bg-gray-50 text-sm font-medium transition-all duration-200 swiss-mono"
                  >
                    Load More
                  </button>
                <% end %>
              <% end %>
            </div>
          </div>
          
    <!-- News -->
          <div class="border border-gray-200 overflow-hidden flex flex-col bg-white">
            <div class="px-4 py-2 border-b border-gray-200 bg-gray-50">
              <div class="flex items-center justify-between">
                <h2 class="text-sm font-semibold text-gray-900 swiss-mono">NEWS</h2>
                <span class="text-xs text-gray-500 swiss-mono">{length(@news_articles)}</span>
              </div>
            </div>
            <div class="flex-1 overflow-y-auto p-4 space-y-3 smooth-scroll" id="news-pane">
              <%= if @news_loading do %>
                <.skeleton_loader />
              <% else %>
                <%= if @news_articles == [] and @search_query != "" do %>
                  <p class="text-gray-400 text-center py-12 text-sm swiss-mono">No results found</p>
                <% else %>
                  <%= for {article, index} <- Enum.with_index(@news_articles) do %>
                    <.paper_card article={article} index={index} color="news" />
                  <% end %>
                <% end %>
                <%= if length(@news_articles) > 0 do %>
                  <button
                    phx-click="load_more"
                    phx-value-pane="news"
                    class="w-full py-2 mt-2 bg-white border border-gray-300 hover:border-gray-900 hover:bg-gray-50 text-sm font-medium transition-all duration-200 swiss-mono"
                  >
                    Load More
                  </button>
                <% end %>
              <% end %>
            </div>
          </div>
          
    <!-- Forums -->
          <div class="border border-gray-200 overflow-hidden flex flex-col bg-white">
            <div class="px-4 py-2 border-b border-gray-200 bg-gray-50">
              <div class="flex items-center justify-between">
                <h2 class="text-sm font-semibold text-gray-900 swiss-mono">FORUMS</h2>
                <span class="text-xs text-gray-500 swiss-mono">{length(@user_content)}</span>
              </div>
            </div>
            <div class="flex-1 overflow-y-auto p-4 space-y-3 smooth-scroll" id="user-content-pane">
              <%= if @user_content_loading do %>
                <.skeleton_loader />
              <% else %>
                <%= if @user_content == [] and @search_query != "" do %>
                  <p class="text-gray-400 text-center py-12 text-sm swiss-mono">No results found</p>
                <% else %>
                  <%= for {content, index} <- Enum.with_index(@user_content) do %>
                    <.paper_card article={content} index={index} color="forums" />
                  <% end %>
                <% end %>
                <%= if length(@user_content) > 0 do %>
                  <button
                    phx-click="load_more"
                    phx-value-pane="user"
                    class="w-full py-2 mt-2 bg-white border border-gray-300 hover:border-gray-900 hover:bg-gray-50 text-sm font-medium transition-all duration-200 swiss-mono"
                  >
                    Load More
                  </button>
                <% end %>
              <% end %>
            </div>
          </div>
          
    <!-- Web -->
          <div class="border border-gray-200 overflow-hidden flex flex-col bg-white">
            <div class="px-4 py-2 border-b border-gray-200 bg-gray-50">
              <div class="flex items-center justify-between">
                <h2 class="text-sm font-semibold text-gray-900 swiss-mono">WEB</h2>
                <span class="text-xs text-gray-500 swiss-mono">{length(@web_results)}</span>
              </div>
            </div>
            <div class="flex-1 overflow-y-auto p-4 space-y-3 smooth-scroll" id="web-results-pane">
              <%= if @web_results_loading do %>
                <.skeleton_loader />
              <% else %>
                <%= if @web_results == [] and @search_query != "" do %>
                  <p class="text-gray-400 text-center py-12 text-sm swiss-mono">No results found</p>
                <% else %>
                  <%= for {result, index} <- Enum.with_index(@web_results) do %>
                    <.paper_card article={result} index={index} color="web" />
                  <% end %>
                <% end %>
                <%= if length(@web_results) > 0 do %>
                  <button
                    phx-click="load_more"
                    phx-value-pane="web"
                    class="w-full py-2 mt-2 bg-white border border-gray-300 hover:border-gray-900 hover:bg-gray-50 text-sm font-medium transition-all duration-200 swiss-mono"
                  >
                    Load More
                  </button>
                <% end %>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Skeleton loader component
  def skeleton_loader(assigns) do
    ~H"""
    <div class="space-y-3" role="status" aria-label="Loading">
      <%= for _i <- 1..5 do %>
        <div class="animate-pulse bg-white border-l-2 border-gray-200 p-4">
          <div class="h-4 bg-gray-200 rounded w-3/4 mb-3"></div>
          <div class="h-3 bg-gray-200 rounded w-1/2 mb-3"></div>
          <div class="space-y-2">
            <div class="h-3 bg-gray-200 rounded w-full"></div>
            <div class="h-3 bg-gray-200 rounded w-5/6"></div>
          </div>
        </div>
      <% end %>
      <span class="sr-only">Loading results...</span>
    </div>
    """
  end

  # Component for minimal card design
  attr :article, :map, required: true
  attr :index, :integer, required: true
  attr :color, :string, default: "scholarly"

  def paper_card(assigns) do
    accent_color =
      case assigns.color do
        "scholarly" -> "#fad608"
        "news" -> "#e3001b"
        "forums" -> "#0066cc"
        "web" -> "#888888"
        _ -> "#fad608"
      end

    assigns = assign(assigns, :accent_color, accent_color)

    ~H"""
    <div class="result-card bg-white border-l-2 border-gray-200 p-4 hover:border-l-4 hover:bg-gray-50 group transition-all duration-200">
      <a href={@article.url} target="_blank" class="block">
        <h3 class="text-sm font-semibold text-gray-900 leading-snug mb-2">
          {@article.title}
        </h3>

        <div class="flex flex-wrap gap-2 mb-2 text-xs">
          <%= if Map.get(@article, :authors) do %>
            <span class="text-gray-600">{@article.authors}</span>
          <% end %>

          <%= if Map.get(@article, :source) do %>
            <span class="text-gray-500">· {@article.source}</span>
          <% end %>

          <%= if Map.get(@article, :date) do %>
            <span class="text-gray-400 swiss-mono">· {@article.date}</span>
          <% end %>
        </div>

        <p class="text-xs text-gray-600 leading-relaxed line-clamp-2">
          {@article.description}
        </p>

        <div class="mt-2 pt-2 border-t border-gray-100">
          <span
            class="text-xs font-medium group-hover:underline transition-all"
            style={"color: #{@accent_color}"}
          >
            Read more →
          </span>
        </div>
      </a>
    </div>
    """
  end
end
