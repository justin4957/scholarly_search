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
     |> assign(:dark_mode, false)}
  end

  @impl true
  def handle_event("toggle_theme", _params, socket) do
    {:noreply, assign(socket, :dark_mode, !socket.assigns.dark_mode)}
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
    <div class={[
      "min-h-screen transition-colors duration-300",
      if(@dark_mode,
        do: "bg-gradient-to-br from-[#0a1628] via-[#1a2942] to-[#0a1628]",
        else: "bg-white"
      )
    ]}>
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
            <form phx-submit="search" class="flex-1 flex gap-2">
              <div class="flex-1 relative">
                <input
                  type="text"
                  name="query"
                  value={@search_query}
                  placeholder="Search across scholarly articles, news, forums, and web..."
                  class={[
                    "search-input w-full px-4 py-2 text-sm border focus:outline-none transition-all duration-200",
                    if(@dark_mode,
                      do:
                        "bg-white/10 backdrop-blur-md border-white/20 text-white placeholder-gray-400 focus:border-[#fad608] focus:bg-white/15",
                      else: "bg-white border-gray-300 text-gray-900 focus:border-gray-900"
                    )
                  ]}
                  autofocus
                />
                <%= if @searching do %>
                  <div class="absolute right-3 top-1/2 -translate-y-1/2">
                    <div class={[
                      "w-4 h-4 border-2 rounded-full animate-spin",
                      if(@dark_mode,
                        do: "border-gray-600 border-t-[#fad608]",
                        else: "border-gray-300 border-t-[#fad608]"
                      )
                    ]}>
                    </div>
                  </div>
                <% end %>
              </div>
              <button
                type="submit"
                class={[
                  "swiss-button px-6 py-2 text-sm font-semibold border transition-all duration-300 disabled:opacity-50",
                  if(@dark_mode,
                    do:
                      "bg-white/10 backdrop-blur-md text-white border-white/20 hover:bg-[#fad608] hover:text-black hover:border-[#fad608]",
                    else: "bg-gray-900 text-white border-gray-900 hover:bg-[#fad608] hover:text-black"
                  )
                ]}
                disabled={@searching}
              >
                {if @searching, do: "Searching", else: "Search"}
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
          </div>
        </div>
      </div>
      
    <!-- Four-Pane Grid Interface -->
      <div class="max-w-[1600px] mx-auto p-4">
        <div class="grid grid-cols-2 gap-4 h-[calc(100vh-100px)]">
          <!-- Scholarly Articles -->
          <div class={[
            "border overflow-hidden flex flex-col transition-all duration-300 shadow-lg",
            if(@dark_mode,
              do: "bg-white/5 backdrop-blur-md border-white/10",
              else: "bg-white border-gray-200"
            )
          ]}>
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
          <div class={[
            "border overflow-hidden flex flex-col transition-all duration-300 shadow-lg",
            if(@dark_mode,
              do: "bg-white/5 backdrop-blur-md border-white/10",
              else: "bg-white border-gray-200"
            )
          ]}>
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
                    <.paper_card article={article} index={index} color="news" dark_mode={@dark_mode} />
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
          <div class={[
            "border overflow-hidden flex flex-col transition-all duration-300 shadow-lg",
            if(@dark_mode,
              do: "bg-white/5 backdrop-blur-md border-white/10",
              else: "bg-white border-gray-200"
            )
          ]}>
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
          <div class={[
            "border overflow-hidden flex flex-col transition-all duration-300 shadow-lg",
            if(@dark_mode,
              do: "bg-white/5 backdrop-blur-md border-white/10",
              else: "bg-white border-gray-200"
            )
          ]}>
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
