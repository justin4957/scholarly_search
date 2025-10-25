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
     |> assign(:web_results_loading, false)
     |> assign(:dark_mode, false)
     |> assign(:view_mode, "grid")
     |> assign(:active_pane, 0)
     |> assign(:enable_animations, true)
     |> assign(:book_mode, false)
     |> assign(:scholarly_page_index, 0)
     |> assign(:news_page_index, 0)
     |> assign(:user_page_index, 0)
     |> assign(:web_page_index, 0)}
  end

  @impl true
  def handle_event("toggle_theme", _params, socket) do
    {:noreply, assign(socket, :dark_mode, !socket.assigns.dark_mode)}
  end

  @impl true
  def handle_event("change_view_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :view_mode, mode)}
  end

  @impl true
  def handle_event("next_pane", _params, socket) do
    next_pane = rem(socket.assigns.active_pane + 1, 4)
    {:noreply, assign(socket, :active_pane, next_pane)}
  end

  @impl true
  def handle_event("prev_pane", _params, socket) do
    prev_pane = rem(socket.assigns.active_pane - 1 + 4, 4)
    {:noreply, assign(socket, :active_pane, prev_pane)}
  end

  @impl true
  def handle_event("toggle_animations", _params, socket) do
    {:noreply, assign(socket, :enable_animations, !socket.assigns.enable_animations)}
  end

  @impl true
  def handle_event("toggle_book_mode", _params, socket) do
    {:noreply, assign(socket, :book_mode, !socket.assigns.book_mode)}
  end

  @impl true
  def handle_event("flip_page", %{"pane" => pane, "direction" => direction}, socket) do
    delta = if direction == "next", do: 1, else: -1

    socket =
      case pane do
        "scholarly" ->
          current_index = socket.assigns.scholarly_page_index
          max_pages = div(length(socket.assigns.scholarly_articles), 5)
          new_index = max(0, min(current_index + delta, max_pages))
          assign(socket, :scholarly_page_index, new_index)

        "news" ->
          current_index = socket.assigns.news_page_index
          max_pages = div(length(socket.assigns.news_articles), 5)
          new_index = max(0, min(current_index + delta, max_pages))
          assign(socket, :news_page_index, new_index)

        "user" ->
          current_index = socket.assigns.user_page_index
          max_pages = div(length(socket.assigns.user_content), 5)
          new_index = max(0, min(current_index + delta, max_pages))
          assign(socket, :user_page_index, new_index)

        "web" ->
          current_index = socket.assigns.web_page_index
          max_pages = div(length(socket.assigns.web_results), 5)
          new_index = max(0, min(current_index + delta, max_pages))
          assign(socket, :web_page_index, new_index)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply,
     socket
     |> assign(:search_query, "")
     |> assign(:scholarly_articles, [])
     |> assign(:news_articles, [])
     |> assign(:user_content, [])
     |> assign(:web_results, [])}
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

  # Helper function to generate pane-specific classes based on view mode
  defp get_pane_classes("grid", _pane_index, _active_pane, _animations_enabled) do
    "transition-all duration-500"
  end

  defp get_pane_classes("carousel", pane_index, active_pane, animations_enabled) do
    transition = if animations_enabled, do: "transition-all duration-500", else: ""

    if pane_index == active_pane do
      "#{transition} absolute inset-0 opacity-100 scale-100 z-20"
    else
      "#{transition} absolute inset-0 opacity-0 scale-95 pointer-events-none z-10"
    end
  end

  defp get_pane_classes("perspective", pane_index, active_pane, animations_enabled) do
    transition = if animations_enabled, do: "transition-all duration-700", else: ""

    # Calculate rotation and z-position based on pane index and active pane
    offset = pane_index - active_pane
    opacity = if abs(offset) > 1, do: "opacity-30", else: "opacity-100"
    z_index = 20 - abs(offset)

    "#{transition} absolute inset-0 #{opacity} z-#{z_index}"
    |> String.trim()
    |> then(fn classes ->
      "#{classes} perspective-pane-#{pane_index}"
    end)
  end

  # Helper to get paginated results for glass book mode
  defp get_page_items(items, page_index) do
    items
    |> Enum.drop(page_index * 5)
    |> Enum.take(5)
  end

  # Helper to calculate total pages
  defp total_pages(items) do
    max(1, div(length(items) + 4, 5))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={[
      "min-h-screen transition-colors duration-300 relative overflow-hidden",
      if(@dark_mode,
        do: "bg-gradient-to-br from-[#0a1628] via-[#1a2942] to-[#0a1628]",
        else: "bg-white"
      )
    ]}>
      <!-- Atmospheric Background Effects -->
      <%= if @dark_mode and @enable_animations do %>
        <!-- Animated Particles -->
        <div class="absolute inset-0 overflow-hidden pointer-events-none">
          <%= for i <- 1..30 do %>
            <div
              class="absolute w-1 h-1 bg-white/40 rounded-full animate-float"
              style={"
                left: #{rem(i * 37, 100)}%;
                top: #{rem(i * 53, 100)}%;
                animation-delay: #{rem(i * 200, 3000)}ms;
                animation-duration: #{15000 + rem(i * 500, 10000)}ms;
              "}
            >
            </div>
          <% end %>
        </div>
        <!-- Radial Gradient Overlay -->
        <div class="absolute inset-0 bg-radial-gradient from-transparent via-transparent to-[#0a1628]/50 pointer-events-none">
        </div>
      <% end %>
      <!-- Minimal Header -->
      <div class={[
        "sticky top-0 z-20 backdrop-blur-sm border-b transition-colors duration-300",
        if(@dark_mode,
          do: "bg-gray-900/80 border-gray-700/50",
          else: "bg-white/95 border-gray-200"
        )
      ]}>
        <div class="max-w-[1600px] mx-auto px-6 py-4">
          <div class="flex items-center gap-4">
            <!-- Logo Mark -->
            <div class="flex items-center gap-2">
              <span class="inline-block w-1 h-6 bg-[#fad608]"></span>
              <h1 class={[
                "text-lg font-bold tracking-tight swiss-title transition-colors duration-300",
                if(@dark_mode, do: "text-white", else: "text-gray-900")
              ]}>
                ScholarlySearch
              </h1>
            </div>
            
    <!-- Search Form -->
            <form
              phx-submit="search"
              class="flex-1 flex gap-2"
              phx-hook="SearchShortcut"
              id="search-form"
            >
              <div class="flex-1 relative group">
                <!-- Search Icon -->
                <div class="absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class={[
                      "h-5 w-5 transition-colors duration-200",
                      if(@dark_mode, do: "text-gray-400", else: "text-gray-500")
                    ]}
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                    />
                  </svg>
                </div>

                <input
                  type="text"
                  name="query"
                  value={@search_query}
                  placeholder="Search across scholarly articles, news, forums, and web..."
                  id="search-input"
                  class={[
                    "search-input w-full pl-12 pr-20 py-3 text-sm rounded-full border focus:outline-none transition-all duration-300",
                    if(@dark_mode,
                      do:
                        "bg-white/10 backdrop-blur-md border-white/20 text-white placeholder-gray-400 focus:border-[#fad608] focus:bg-white/15 focus:shadow-[0_0_0_3px_rgba(250,214,8,0.1),0_8px_32px_rgba(0,0,0,0.15)]",
                      else:
                        "bg-white border-gray-300 text-gray-900 focus:border-[#fad608] focus:shadow-[0_0_0_3px_rgba(250,214,8,0.1),0_4px_12px_rgba(0,0,0,0.08)]"
                    )
                  ]}
                  autofocus
                />
                
    <!-- Clear Button -->
                <%= if @search_query != "" and !@searching do %>
                  <button
                    type="button"
                    phx-click="clear_search"
                    class={[
                      "absolute right-12 top-1/2 -translate-y-1/2 p-1 rounded-full transition-all duration-200 hover:scale-110",
                      if(@dark_mode,
                        do: "text-gray-400 hover:text-white hover:bg-white/10",
                        else: "text-gray-500 hover:text-gray-900 hover:bg-gray-100"
                      )
                    ]}
                    aria-label="Clear search"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M6 18L18 6M6 6l12 12"
                      />
                    </svg>
                  </button>
                <% end %>
                
    <!-- Loading Spinner -->
                <%= if @searching do %>
                  <div class="absolute right-12 top-1/2 -translate-y-1/2">
                    <div class={[
                      "w-5 h-5 border-2 rounded-full animate-spin",
                      if(@dark_mode,
                        do: "border-gray-600 border-t-[#fad608]",
                        else: "border-gray-300 border-t-[#fad608]"
                      )
                    ]}>
                    </div>
                  </div>
                <% end %>
                
    <!-- Keyboard Shortcut Hint -->
                <%= if @search_query == "" and !@searching do %>
                  <div class={[
                    "absolute right-4 top-1/2 -translate-y-1/2 px-2 py-1 rounded text-xs font-mono opacity-50 transition-opacity duration-200 group-focus-within:opacity-0 pointer-events-none",
                    if(@dark_mode,
                      do: "bg-white/10 text-gray-400 border border-white/20",
                      else: "bg-gray-100 text-gray-600 border border-gray-300"
                    )
                  ]}>
                    /
                  </div>
                <% end %>
              </div>
              <button
                type="submit"
                class={[
                  "swiss-button px-8 py-3 text-sm font-semibold border rounded-full transition-all duration-300 disabled:opacity-50 hover:scale-105",
                  if(@dark_mode,
                    do:
                      "bg-white/10 backdrop-blur-md text-white border-white/20 hover:bg-[#fad608] hover:text-black hover:border-[#fad608] hover:shadow-[0_0_20px_rgba(250,214,8,0.3)]",
                    else:
                      "bg-gray-900 text-white border-gray-900 hover:bg-[#fad608] hover:text-black hover:shadow-[0_4px_12px_rgba(250,214,8,0.3)]"
                  )
                ]}
                disabled={@searching}
              >
                {if @searching, do: "Searching...", else: "Search"}
              </button>
            </form>
            
    <!-- Theme Toggle -->
            <button
              type="button"
              phx-click="toggle_theme"
              class={[
                "p-2 rounded-lg transition-all duration-300 hover:scale-110",
                if(@dark_mode,
                  do: "bg-white/10 backdrop-blur-md text-yellow-300 hover:bg-white/20",
                  else: "bg-gray-100 text-gray-700 hover:bg-gray-200"
                )
              ]}
              aria-label={if @dark_mode, do: "Switch to light mode", else: "Switch to dark mode"}
            >
              <%= if @dark_mode do %>
                <!-- Sun Icon -->
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
                  />
                </svg>
              <% else %>
                <!-- Moon Icon -->
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
                  />
                </svg>
              <% end %>
            </button>
            
    <!-- View Mode Selector -->
            <div class={[
              "flex gap-1 p-1 rounded-lg transition-all duration-300",
              if(@dark_mode,
                do: "bg-white/10 backdrop-blur-md",
                else: "bg-gray-100"
              )
            ]}>
              <button
                type="button"
                phx-click="change_view_mode"
                phx-value-mode="grid"
                class={[
                  "px-3 py-1 text-xs font-medium rounded transition-all duration-200",
                  if(@view_mode == "grid",
                    do:
                      if(@dark_mode,
                        do: "bg-[#fad608] text-black",
                        else: "bg-white text-gray-900 shadow-sm"
                      ),
                    else:
                      if(@dark_mode,
                        do: "text-gray-400 hover:text-white",
                        else: "text-gray-600 hover:text-gray-900"
                      )
                  )
                ]}
                aria-label="Grid view"
              >
                Grid
              </button>
              <button
                type="button"
                phx-click="change_view_mode"
                phx-value-mode="perspective"
                class={[
                  "px-3 py-1 text-xs font-medium rounded transition-all duration-200",
                  if(@view_mode == "perspective",
                    do:
                      if(@dark_mode,
                        do: "bg-[#fad608] text-black",
                        else: "bg-white text-gray-900 shadow-sm"
                      ),
                    else:
                      if(@dark_mode,
                        do: "text-gray-400 hover:text-white",
                        else: "text-gray-600 hover:text-gray-900"
                      )
                  )
                ]}
                aria-label="Perspective view"
              >
                3D
              </button>
              <button
                type="button"
                phx-click="change_view_mode"
                phx-value-mode="carousel"
                class={[
                  "px-3 py-1 text-xs font-medium rounded transition-all duration-200",
                  if(@view_mode == "carousel",
                    do:
                      if(@dark_mode,
                        do: "bg-[#fad608] text-black",
                        else: "bg-white text-gray-900 shadow-sm"
                      ),
                    else:
                      if(@dark_mode,
                        do: "text-gray-400 hover:text-white",
                        else: "text-gray-600 hover:text-gray-900"
                      )
                  )
                ]}
                aria-label="Carousel view"
              >
                Carousel
              </button>
            </div>
            
    <!-- Book Mode Toggle -->
            <button
              type="button"
              phx-click="toggle_book_mode"
              class={[
                "p-2 rounded-lg transition-all duration-300 hover:scale-110",
                if(@dark_mode,
                  do:
                    if(@book_mode,
                      do: "bg-[#fad608] text-black",
                      else:
                        "bg-white/10 backdrop-blur-md text-gray-400 hover:bg-white/20 hover:text-white"
                    ),
                  else:
                    if(@book_mode,
                      do: "bg-[#fad608] text-black",
                      else: "bg-gray-100 text-gray-600 hover:bg-gray-200"
                    )
                )
              ]}
              aria-label={if @book_mode, do: "Exit book mode", else: "Enter book mode"}
              title={if @book_mode, do: "Exit book mode", else: "Enter book mode"}
            >
              <!-- Book Icon -->
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
                />
              </svg>
            </button>
            
    <!-- Animation Toggle (Accessibility) -->
            <button
              type="button"
              phx-click="toggle_animations"
              class={[
                "p-2 rounded-lg transition-all duration-300",
                if(@dark_mode,
                  do: "bg-white/10 backdrop-blur-md text-gray-400 hover:bg-white/20 hover:text-white",
                  else: "bg-gray-100 text-gray-600 hover:bg-gray-200"
                ),
                if(!@enable_animations, do: "opacity-50")
              ]}
              aria-label={if @enable_animations, do: "Disable animations", else: "Enable animations"}
              title={if @enable_animations, do: "Disable animations", else: "Enable animations"}
            >
              <!-- Sparkles Icon for animations -->
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"
                />
              </svg>
            </button>
          </div>
        </div>
      </div>

      <%= if @book_mode do %>
        <!-- Glass Book Mode - Central Search with Surrounding Panes -->
        <div class="glass-book-container max-w-[1800px] mx-auto">
          <!-- Top Pane - Scholarly Articles -->
          <div
            class={[
              "glass-book-top",
              if(@dark_mode, do: "glass-book-page", else: "glass-book-page-light"),
              if(@enable_animations, do: "page-flip-vertical", else: "")
            ]}
            phx-hook="GlassBookPane"
            id="glass-book-scholarly"
            data-pane="scholarly"
          >
            <div class="glass-book-page-content">
              <div class="glass-book-page-header">
                <h2 class={[
                  "text-sm font-bold swiss-mono tracking-wider",
                  if(@dark_mode, do: "text-[#fad608]", else: "text-gray-900")
                ]}>
                  SCHOLARLY
                </h2>
                <span class={[
                  "text-xs swiss-mono",
                  if(@dark_mode, do: "text-gray-400", else: "text-gray-600")
                ]}>
                  {length(@scholarly_articles)} results
                </span>
              </div>
              <div class="glass-book-page-body">
                <%= if @scholarly_loading do %>
                  <div class="flex items-center justify-center h-full">
                    <div class={[
                      "w-8 h-8 border-2 rounded-full animate-spin",
                      if(@dark_mode,
                        do: "border-gray-600 border-t-[#fad608]",
                        else: "border-gray-300 border-t-[#fad608]"
                      )
                    ]}>
                    </div>
                  </div>
                <% else %>
                  <%= for article <- get_page_items(@scholarly_articles, @scholarly_page_index) do %>
                    <a
                      href={article.url}
                      target="_blank"
                      class={[
                        "block p-3 rounded-lg border-l-3 transition-all duration-200 hover:translate-x-1",
                        if(@dark_mode,
                          do: "bg-white/5 hover:bg-white/10 border-[#fad608]",
                          else: "bg-white/50 hover:bg-white/80 border-[#fad608]"
                        )
                      ]}
                    >
                      <h3 class={[
                        "text-xs font-semibold mb-1 line-clamp-2",
                        if(@dark_mode, do: "text-white", else: "text-gray-900")
                      ]}>
                        {article.title}
                      </h3>
                      <p class={[
                        "text-xs line-clamp-1",
                        if(@dark_mode, do: "text-gray-400", else: "text-gray-600")
                      ]}>
                        {article.authors}
                      </p>
                    </a>
                  <% end %>
                <% end %>
              </div>
              <div class="glass-book-page-number">
                <span class={if(@dark_mode, do: "text-white", else: "text-gray-900")}>
                  {@scholarly_page_index + 1} / {total_pages(@scholarly_articles)}
                </span>
              </div>
              <div class="scroll-hint">
                Scroll to flip
              </div>
            </div>
          </div>
          
    <!-- Left Pane - News Articles -->
          <div
            class={[
              "glass-book-left",
              if(@dark_mode, do: "glass-book-page", else: "glass-book-page-light"),
              if(@enable_animations, do: "page-flip-horizontal", else: "")
            ]}
            phx-hook="GlassBookPane"
            id="glass-book-news"
            data-pane="news"
          >
            <div class="glass-book-page-content">
              <div class="glass-book-page-header">
                <h2 class={[
                  "text-sm font-bold swiss-mono tracking-wider",
                  if(@dark_mode, do: "text-[#e3001b]", else: "text-gray-900")
                ]}>
                  NEWS
                </h2>
                <span class={[
                  "text-xs swiss-mono",
                  if(@dark_mode, do: "text-gray-400", else: "text-gray-600")
                ]}>
                  {length(@news_articles)} results
                </span>
              </div>
              <div class="glass-book-page-body">
                <%= if @news_loading do %>
                  <div class="flex items-center justify-center h-full">
                    <div class={[
                      "w-8 h-8 border-2 rounded-full animate-spin",
                      if(@dark_mode,
                        do: "border-gray-600 border-t-[#e3001b]",
                        else: "border-gray-300 border-t-[#e3001b]"
                      )
                    ]}>
                    </div>
                  </div>
                <% else %>
                  <%= for article <- get_page_items(@news_articles, @news_page_index) do %>
                    <a
                      href={article.url}
                      target="_blank"
                      class={[
                        "block p-3 rounded-lg border-l-3 transition-all duration-200 hover:translate-x-1",
                        if(@dark_mode,
                          do: "bg-white/5 hover:bg-white/10 border-[#e3001b]",
                          else: "bg-white/50 hover:bg-white/80 border-[#e3001b]"
                        )
                      ]}
                    >
                      <h3 class={[
                        "text-xs font-semibold mb-1 line-clamp-2",
                        if(@dark_mode, do: "text-white", else: "text-gray-900")
                      ]}>
                        {article.title}
                      </h3>
                      <p class={[
                        "text-xs line-clamp-1",
                        if(@dark_mode, do: "text-gray-400", else: "text-gray-600")
                      ]}>
                        {article.source} · {article.date}
                      </p>
                    </a>
                  <% end %>
                <% end %>
              </div>
              <div class="glass-book-page-number">
                <span class={if(@dark_mode, do: "text-white", else: "text-gray-900")}>
                  {@news_page_index + 1} / {total_pages(@news_articles)}
                </span>
              </div>
              <div class="scroll-hint">
                Scroll to flip
              </div>
            </div>
          </div>
          
    <!-- Center - Main Search Info -->
          <div class="glass-book-center">
            <div class={[
              "text-center p-8 rounded-2xl",
              if(@dark_mode,
                do: "bg-white/5 backdrop-blur-xl border border-white/10",
                else: "bg-white/80 backdrop-blur-xl border border-gray-200"
              )
            ]}>
              <%= if @search_query != "" do %>
                <h2 class={[
                  "text-2xl font-bold mb-2",
                  if(@dark_mode, do: "text-white", else: "text-gray-900")
                ]}>
                  "{@search_query}"
                </h2>
                <p class={[
                  "text-sm swiss-mono",
                  if(@dark_mode, do: "text-gray-400", else: "text-gray-600")
                ]}>
                  Hover over a pane and scroll to flip through results
                </p>
              <% else %>
                <h2 class={[
                  "text-2xl font-bold mb-2",
                  if(@dark_mode, do: "text-white", else: "text-gray-900")
                ]}>
                  Glass Book Mode
                </h2>
                <p class={[
                  "text-sm swiss-mono",
                  if(@dark_mode, do: "text-gray-400", else: "text-gray-600")
                ]}>
                  Search to explore results in an immersive book-like interface
                </p>
              <% end %>
            </div>
          </div>
          
    <!-- Right Pane - Forums/User Content -->
          <div
            class={[
              "glass-book-right",
              if(@dark_mode, do: "glass-book-page", else: "glass-book-page-light"),
              if(@enable_animations, do: "page-flip-horizontal", else: "")
            ]}
            phx-hook="GlassBookPane"
            id="glass-book-forums"
            data-pane="user"
          >
            <div class="glass-book-page-content">
              <div class="glass-book-page-header">
                <h2 class={[
                  "text-sm font-bold swiss-mono tracking-wider",
                  if(@dark_mode, do: "text-[#0066cc]", else: "text-gray-900")
                ]}>
                  FORUMS
                </h2>
                <span class={[
                  "text-xs swiss-mono",
                  if(@dark_mode, do: "text-gray-400", else: "text-gray-600")
                ]}>
                  {length(@user_content)} results
                </span>
              </div>
              <div class="glass-book-page-body">
                <%= if @user_content_loading do %>
                  <div class="flex items-center justify-center h-full">
                    <div class={[
                      "w-8 h-8 border-2 rounded-full animate-spin",
                      if(@dark_mode,
                        do: "border-gray-600 border-t-[#0066cc]",
                        else: "border-gray-300 border-t-[#0066cc]"
                      )
                    ]}>
                    </div>
                  </div>
                <% else %>
                  <%= for content <- get_page_items(@user_content, @user_page_index) do %>
                    <a
                      href={content.url}
                      target="_blank"
                      class={[
                        "block p-3 rounded-lg border-l-3 transition-all duration-200 hover:translate-x-1",
                        if(@dark_mode,
                          do: "bg-white/5 hover:bg-white/10 border-[#0066cc]",
                          else: "bg-white/50 hover:bg-white/80 border-[#0066cc]"
                        )
                      ]}
                    >
                      <h3 class={[
                        "text-xs font-semibold mb-1 line-clamp-2",
                        if(@dark_mode, do: "text-white", else: "text-gray-900")
                      ]}>
                        {content.title}
                      </h3>
                      <p class={[
                        "text-xs line-clamp-1",
                        if(@dark_mode, do: "text-gray-400", else: "text-gray-600")
                      ]}>
                        {content.source}
                      </p>
                    </a>
                  <% end %>
                <% end %>
              </div>
              <div class="glass-book-page-number">
                <span class={if(@dark_mode, do: "text-white", else: "text-gray-900")}>
                  {@user_page_index + 1} / {total_pages(@user_content)}
                </span>
              </div>
              <div class="scroll-hint">
                Scroll to flip
              </div>
            </div>
          </div>
          
    <!-- Bottom Pane - Web Results -->
          <div
            class={[
              "glass-book-bottom",
              if(@dark_mode, do: "glass-book-page", else: "glass-book-page-light"),
              if(@enable_animations, do: "page-flip-vertical", else: "")
            ]}
            phx-hook="GlassBookPane"
            id="glass-book-web"
            data-pane="web"
          >
            <div class="glass-book-page-content">
              <div class="glass-book-page-header">
                <h2 class={[
                  "text-sm font-bold swiss-mono tracking-wider",
                  if(@dark_mode, do: "text-[#888888]", else: "text-gray-900")
                ]}>
                  WEB
                </h2>
                <span class={[
                  "text-xs swiss-mono",
                  if(@dark_mode, do: "text-gray-400", else: "text-gray-600")
                ]}>
                  {length(@web_results)} results
                </span>
              </div>
              <div class="glass-book-page-body">
                <%= if @web_results_loading do %>
                  <div class="flex items-center justify-center h-full">
                    <div class={[
                      "w-8 h-8 border-2 rounded-full animate-spin",
                      if(@dark_mode,
                        do: "border-gray-600 border-t-[#888888]",
                        else: "border-gray-300 border-t-[#888888]"
                      )
                    ]}>
                    </div>
                  </div>
                <% else %>
                  <%= for result <- get_page_items(@web_results, @web_page_index) do %>
                    <a
                      href={result.url}
                      target="_blank"
                      class={[
                        "block p-3 rounded-lg border-l-3 transition-all duration-200 hover:translate-x-1",
                        if(@dark_mode,
                          do: "bg-white/5 hover:bg-white/10 border-[#888888]",
                          else: "bg-white/50 hover:bg-white/80 border-[#888888]"
                        )
                      ]}
                    >
                      <h3 class={[
                        "text-xs font-semibold mb-1 line-clamp-2",
                        if(@dark_mode, do: "text-white", else: "text-gray-900")
                      ]}>
                        {result.title}
                      </h3>
                      <p class={[
                        "text-xs line-clamp-1",
                        if(@dark_mode, do: "text-gray-400", else: "text-gray-600")
                      ]}>
                        {result.url}
                      </p>
                    </a>
                  <% end %>
                <% end %>
              </div>
              <div class="glass-book-page-number">
                <span class={if(@dark_mode, do: "text-white", else: "text-gray-900")}>
                  {@web_page_index + 1} / {total_pages(@web_results)}
                </span>
              </div>
              <div class="scroll-hint">
                Scroll to flip
              </div>
            </div>
          </div>
        </div>
      <% else %>
        
    <!-- Four-Pane Grid Interface -->
        <div class="max-w-[1600px] mx-auto p-4 relative">
          <!-- Carousel Navigation Arrows -->
          <%= if @view_mode in ["carousel", "perspective"] do %>
            <button
              phx-click="prev_pane"
              class={[
                "absolute left-0 top-1/2 -translate-y-1/2 z-30 p-4 transition-all duration-300 hover:scale-110",
                if(@dark_mode,
                  do:
                    "bg-white/10 backdrop-blur-md text-white hover:bg-white/20 border border-white/20",
                  else: "bg-white text-gray-900 hover:bg-gray-50 border border-gray-300 shadow-lg"
                )
              ]}
              aria-label="Previous category"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-6 w-6"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 19l-7-7 7-7"
                />
              </svg>
            </button>

            <button
              phx-click="next_pane"
              class={[
                "absolute right-0 top-1/2 -translate-y-1/2 z-30 p-4 transition-all duration-300 hover:scale-110",
                if(@dark_mode,
                  do:
                    "bg-white/10 backdrop-blur-md text-white hover:bg-white/20 border border-white/20",
                  else: "bg-white text-gray-900 hover:bg-gray-50 border border-gray-300 shadow-lg"
                )
              ]}
              aria-label="Next category"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-6 w-6"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5l7 7-7 7"
                />
              </svg>
            </button>
            
    <!-- Progress Indicators -->
            <div class="absolute bottom-4 left-1/2 -translate-x-1/2 z-30 flex gap-2">
              <%= for pane_index <- 0..3 do %>
                <div class={[
                  "w-2 h-2 rounded-full transition-all duration-300",
                  if(@active_pane == pane_index,
                    do: "bg-[#fad608] w-8",
                    else:
                      if(@dark_mode,
                        do: "bg-white/30 hover:bg-white/50",
                        else: "bg-gray-400 hover:bg-gray-600"
                      )
                  )
                ]}>
                </div>
              <% end %>
            </div>
          <% end %>

          <div class={[
            "h-[calc(100vh-100px)] transition-all duration-500",
            case @view_mode do
              "grid" -> "grid grid-cols-2 gap-4"
              "perspective" -> "perspective-container relative"
              "carousel" -> "carousel-container relative flex items-center justify-center"
              _ -> "grid grid-cols-2 gap-4"
            end
          ]}>
            <!-- Scholarly Articles -->
            <div
              class={[
                "border overflow-hidden flex flex-col shadow-lg",
                if(@dark_mode,
                  do: "bg-white/5 backdrop-blur-md border-white/10",
                  else: "bg-white border-gray-200"
                ),
                get_pane_classes(@view_mode, 0, @active_pane, @enable_animations)
              ]}
              data-pane="scholarly"
            >
              <div class={[
                "px-4 py-2 border-b transition-all duration-300",
                if(@dark_mode,
                  do: "border-white/10 bg-white/5",
                  else: "border-gray-200 bg-gray-50"
                )
              ]}>
                <div class="flex items-center justify-between">
                  <h2 class={[
                    "text-sm font-semibold swiss-mono transition-colors duration-300",
                    if(@dark_mode, do: "text-white", else: "text-gray-900")
                  ]}>
                    SCHOLARLY
                  </h2>
                  <span class={[
                    "text-xs swiss-mono transition-colors duration-300",
                    if(@dark_mode, do: "text-gray-400", else: "text-gray-500")
                  ]}>
                    {length(@scholarly_articles)}
                  </span>
                </div>
              </div>
              <div class="flex-1 overflow-y-auto p-4 space-y-3 smooth-scroll" id="scholarly-pane">
                <%= if @scholarly_loading do %>
                  <.skeleton_loader dark_mode={@dark_mode} />
                <% else %>
                  <%= if @scholarly_articles == [] and @search_query != "" do %>
                    <p class={[
                      "text-center py-12 text-sm swiss-mono transition-colors duration-300",
                      if(@dark_mode, do: "text-gray-500", else: "text-gray-400")
                    ]}>
                      No results found
                    </p>
                  <% else %>
                    <%= for {article, index} <- Enum.with_index(@scholarly_articles) do %>
                      <.paper_card
                        article={article}
                        index={index}
                        color="scholarly"
                        dark_mode={@dark_mode}
                      />
                    <% end %>
                  <% end %>
                  <%= if length(@scholarly_articles) > 0 do %>
                    <button
                      phx-click="load_more"
                      phx-value-pane="scholarly"
                      class={[
                        "w-full py-2 mt-2 border text-sm font-medium transition-all duration-200 swiss-mono",
                        if(@dark_mode,
                          do:
                            "bg-white/5 border-white/20 hover:border-[#fad608] hover:bg-white/10 text-white",
                          else:
                            "bg-white border-gray-300 hover:border-gray-900 hover:bg-gray-50 text-gray-900"
                        )
                      ]}
                    >
                      Load More
                    </button>
                  <% end %>
                <% end %>
              </div>
            </div>
            
    <!-- News -->
            <div
              class={[
                "border overflow-hidden flex flex-col shadow-lg",
                if(@dark_mode,
                  do: "bg-white/5 backdrop-blur-md border-white/10",
                  else: "bg-white border-gray-200"
                ),
                get_pane_classes(@view_mode, 1, @active_pane, @enable_animations)
              ]}
              data-pane="news"
            >
              <div class={[
                "px-4 py-2 border-b transition-all duration-300",
                if(@dark_mode,
                  do: "border-white/10 bg-white/5",
                  else: "border-gray-200 bg-gray-50"
                )
              ]}>
                <div class="flex items-center justify-between">
                  <h2 class={[
                    "text-sm font-semibold swiss-mono transition-colors duration-300",
                    if(@dark_mode, do: "text-white", else: "text-gray-900")
                  ]}>
                    NEWS
                  </h2>
                  <span class={[
                    "text-xs swiss-mono transition-colors duration-300",
                    if(@dark_mode, do: "text-gray-400", else: "text-gray-500")
                  ]}>
                    {length(@news_articles)}
                  </span>
                </div>
              </div>
              <div class="flex-1 overflow-y-auto p-4 space-y-3 smooth-scroll" id="news-pane">
                <%= if @news_loading do %>
                  <.skeleton_loader dark_mode={@dark_mode} />
                <% else %>
                  <%= if @news_articles == [] and @search_query != "" do %>
                    <p class={[
                      "text-center py-12 text-sm swiss-mono transition-colors duration-300",
                      if(@dark_mode, do: "text-gray-500", else: "text-gray-400")
                    ]}>
                      No results found
                    </p>
                  <% else %>
                    <%= for {article, index} <- Enum.with_index(@news_articles) do %>
                      <.paper_card
                        article={article}
                        index={index}
                        color="news"
                        dark_mode={@dark_mode}
                      />
                    <% end %>
                  <% end %>
                  <%= if length(@news_articles) > 0 do %>
                    <button
                      phx-click="load_more"
                      phx-value-pane="news"
                      class={[
                        "w-full py-2 mt-2 border text-sm font-medium transition-all duration-200 swiss-mono",
                        if(@dark_mode,
                          do:
                            "bg-white/5 border-white/20 hover:border-[#fad608] hover:bg-white/10 text-white",
                          else:
                            "bg-white border-gray-300 hover:border-gray-900 hover:bg-gray-50 text-gray-900"
                        )
                      ]}
                    >
                      Load More
                    </button>
                  <% end %>
                <% end %>
              </div>
            </div>
            
    <!-- Forums -->
            <div
              class={[
                "border overflow-hidden flex flex-col shadow-lg",
                if(@dark_mode,
                  do: "bg-white/5 backdrop-blur-md border-white/10",
                  else: "bg-white border-gray-200"
                ),
                get_pane_classes(@view_mode, 2, @active_pane, @enable_animations)
              ]}
              data-pane="forums"
            >
              <div class={[
                "px-4 py-2 border-b transition-all duration-300",
                if(@dark_mode,
                  do: "border-white/10 bg-white/5",
                  else: "border-gray-200 bg-gray-50"
                )
              ]}>
                <div class="flex items-center justify-between">
                  <h2 class={[
                    "text-sm font-semibold swiss-mono transition-colors duration-300",
                    if(@dark_mode, do: "text-white", else: "text-gray-900")
                  ]}>
                    FORUMS
                  </h2>
                  <span class={[
                    "text-xs swiss-mono transition-colors duration-300",
                    if(@dark_mode, do: "text-gray-400", else: "text-gray-500")
                  ]}>
                    {length(@user_content)}
                  </span>
                </div>
              </div>
              <div class="flex-1 overflow-y-auto p-4 space-y-3 smooth-scroll" id="user-content-pane">
                <%= if @user_content_loading do %>
                  <.skeleton_loader dark_mode={@dark_mode} />
                <% else %>
                  <%= if @user_content == [] and @search_query != "" do %>
                    <p class={[
                      "text-center py-12 text-sm swiss-mono transition-colors duration-300",
                      if(@dark_mode, do: "text-gray-500", else: "text-gray-400")
                    ]}>
                      No results found
                    </p>
                  <% else %>
                    <%= for {content, index} <- Enum.with_index(@user_content) do %>
                      <.paper_card
                        article={content}
                        index={index}
                        color="forums"
                        dark_mode={@dark_mode}
                      />
                    <% end %>
                  <% end %>
                  <%= if length(@user_content) > 0 do %>
                    <button
                      phx-click="load_more"
                      phx-value-pane="user"
                      class={[
                        "w-full py-2 mt-2 border text-sm font-medium transition-all duration-200 swiss-mono",
                        if(@dark_mode,
                          do:
                            "bg-white/5 border-white/20 hover:border-[#fad608] hover:bg-white/10 text-white",
                          else:
                            "bg-white border-gray-300 hover:border-gray-900 hover:bg-gray-50 text-gray-900"
                        )
                      ]}
                    >
                      Load More
                    </button>
                  <% end %>
                <% end %>
              </div>
            </div>
            
    <!-- Web -->
            <div
              class={[
                "border overflow-hidden flex flex-col shadow-lg",
                if(@dark_mode,
                  do: "bg-white/5 backdrop-blur-md border-white/10",
                  else: "bg-white border-gray-200"
                ),
                get_pane_classes(@view_mode, 3, @active_pane, @enable_animations)
              ]}
              data-pane="web"
            >
              <div class={[
                "px-4 py-2 border-b transition-all duration-300",
                if(@dark_mode,
                  do: "border-white/10 bg-white/5",
                  else: "border-gray-200 bg-gray-50"
                )
              ]}>
                <div class="flex items-center justify-between">
                  <h2 class={[
                    "text-sm font-semibold swiss-mono transition-colors duration-300",
                    if(@dark_mode, do: "text-white", else: "text-gray-900")
                  ]}>
                    WEB
                  </h2>
                  <span class={[
                    "text-xs swiss-mono transition-colors duration-300",
                    if(@dark_mode, do: "text-gray-400", else: "text-gray-500")
                  ]}>
                    {length(@web_results)}
                  </span>
                </div>
              </div>
              <div class="flex-1 overflow-y-auto p-4 space-y-3 smooth-scroll" id="web-results-pane">
                <%= if @web_results_loading do %>
                  <.skeleton_loader dark_mode={@dark_mode} />
                <% else %>
                  <%= if @web_results == [] and @search_query != "" do %>
                    <p class={[
                      "text-center py-12 text-sm swiss-mono transition-colors duration-300",
                      if(@dark_mode, do: "text-gray-500", else: "text-gray-400")
                    ]}>
                      No results found
                    </p>
                  <% else %>
                    <%= for {result, index} <- Enum.with_index(@web_results) do %>
                      <.paper_card article={result} index={index} color="web" dark_mode={@dark_mode} />
                    <% end %>
                  <% end %>
                  <%= if length(@web_results) > 0 do %>
                    <button
                      phx-click="load_more"
                      phx-value-pane="web"
                      class={[
                        "w-full py-2 mt-2 border text-sm font-medium transition-all duration-200 swiss-mono",
                        if(@dark_mode,
                          do:
                            "bg-white/5 border-white/20 hover:border-[#fad608] hover:bg-white/10 text-white",
                          else:
                            "bg-white border-gray-300 hover:border-gray-900 hover:bg-gray-50 text-gray-900"
                        )
                      ]}
                    >
                      Load More
                    </button>
                  <% end %>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Skeleton loader component
  attr :dark_mode, :boolean, default: false

  def skeleton_loader(assigns) do
    ~H"""
    <div class="space-y-3" role="status" aria-label="Loading">
      <%= for _i <- 1..5 do %>
        <div class={[
          "animate-pulse border-l-2 p-4 transition-all duration-300",
          if(@dark_mode,
            do: "bg-white/5 border-white/20",
            else: "bg-white border-gray-200"
          )
        ]}>
          <div class={[
            "h-4 rounded w-3/4 mb-3 transition-colors duration-300",
            if(@dark_mode, do: "bg-white/20", else: "bg-gray-200")
          ]}>
          </div>
          <div class={[
            "h-3 rounded w-1/2 mb-3 transition-colors duration-300",
            if(@dark_mode, do: "bg-white/20", else: "bg-gray-200")
          ]}>
          </div>
          <div class="space-y-2">
            <div class={[
              "h-3 rounded w-full transition-colors duration-300",
              if(@dark_mode, do: "bg-white/20", else: "bg-gray-200")
            ]}>
            </div>
            <div class={[
              "h-3 rounded w-5/6 transition-colors duration-300",
              if(@dark_mode, do: "bg-white/20", else: "bg-gray-200")
            ]}>
            </div>
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
  attr :dark_mode, :boolean, default: false

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
    <div class={[
      "result-card border-l-2 p-4 hover:border-l-4 group transition-all duration-200",
      if(@dark_mode,
        do: "bg-white/5 backdrop-blur-sm border-white/20 hover:bg-white/10",
        else: "bg-white border-gray-200 hover:bg-gray-50"
      )
    ]}>
      <a href={@article.url} target="_blank" class="block">
        <h3 class={[
          "text-sm font-semibold leading-snug mb-2 transition-colors duration-300",
          if(@dark_mode, do: "text-white", else: "text-gray-900")
        ]}>
          {@article.title}
        </h3>

        <div class="flex flex-wrap gap-2 mb-2 text-xs">
          <%= if Map.get(@article, :authors) do %>
            <span class={[
              "transition-colors duration-300",
              if(@dark_mode, do: "text-gray-400", else: "text-gray-600")
            ]}>
              {@article.authors}
            </span>
          <% end %>

          <%= if Map.get(@article, :source) do %>
            <span class={[
              "transition-colors duration-300",
              if(@dark_mode, do: "text-gray-500", else: "text-gray-500")
            ]}>
              · {@article.source}
            </span>
          <% end %>

          <%= if Map.get(@article, :date) do %>
            <span class={[
              "swiss-mono transition-colors duration-300",
              if(@dark_mode, do: "text-gray-500", else: "text-gray-400")
            ]}>
              · {@article.date}
            </span>
          <% end %>
        </div>

        <p class={[
          "text-xs leading-relaxed line-clamp-2 transition-colors duration-300",
          if(@dark_mode, do: "text-gray-400", else: "text-gray-600")
        ]}>
          {@article.description}
        </p>

        <div class={[
          "mt-2 pt-2 border-t transition-colors duration-300",
          if(@dark_mode, do: "border-white/10", else: "border-gray-100")
        ]}>
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
