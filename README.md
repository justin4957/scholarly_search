# ScholarlySearch

A Phoenix LiveView application providing a unified search interface across multiple content types: scholarly articles, news, forums, and general web results.

## Features

- **Four-Pane Search Interface**: Simultaneously search and display results across four content categories
  - 📚 **Scholarly Articles** (Top-Left): Academic journals, research papers, and scholarly publications
  - 📰 **News & Current Events** (Top-Right): Latest news articles from major outlets
  - 💬 **Forums & Community** (Bottom-Left): User-generated content from Reddit, Stack Overflow, forums
  - 🌐 **Web Results** (Bottom-Right): General web search results

- **Real-time Search**: LiveView-powered interface with instant updates
- **Paginated Results**: Load more results with a "book paper leaf" stacked design
- **Responsive Design**: Clean, modern interface built with TailwindCSS
- **Extensible Architecture**: Modular design for easy API integration

## Architecture

The application is structured with composability and reusability in mind:

```
lib/scholarly_search/
├── search/
│   ├── scholarly_articles.ex  # Academic search module
│   ├── news_articles.ex        # News search module
│   ├── user_content.ex         # Forum/community search module
│   └── web_results.ex          # General web search module
└── ...

lib/scholarly_search_web/
├── live/
│   └── search_live.ex          # Main LiveView component
└── ...
```

### Search Modules

Each search module (`ScholarlyArticles`, `NewsArticles`, `UserContent`, `WebResults`) is designed for easy integration with external APIs:

- **Scholarly Articles**: Ready for integration with Semantic Scholar, CrossRef, PubMed, arXiv
- **News Articles**: Ready for integration with NewsAPI, Google News, Reuters
- **User Content**: Ready for integration with Reddit, Stack Exchange, Hacker News
- **Web Results**: Ready for integration with Google Custom Search, Bing, DuckDuckGo

Currently, the modules return mock data for demonstration purposes. To integrate real APIs:

1. Add API keys to `config/runtime.exs`
2. Implement the `fetch_from_*` functions in each module
3. Replace `generate_mock_results/2` calls with actual API calls

## Getting Started

### Prerequisites

- Elixir 1.14 or later
- Erlang/OTP 25 or later
- PostgreSQL 14 or later
- Node.js 18 or later (for assets)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd scholarly_search
```

2. Install dependencies:
```bash
mix deps.get
cd assets && npm install && cd ..
```

3. Create and configure your database:
```bash
mix ecto.create
```

4. Start the Phoenix server:
```bash
mix phx.server
```

Now visit [`localhost:4000`](http://localhost:4000) from your browser.

### Running in Development

You can also run the server inside IEx for interactive development:

```bash
iex -S mix phx.server
```

## Configuration

### API Keys

To integrate real search APIs, add your API keys to `config/runtime.exs`:

```elixir
config :scholarly_search,
  semantic_scholar_api_key: System.get_env("SEMANTIC_SCHOLAR_API_KEY"),
  newsapi_key: System.get_env("NEWSAPI_KEY"),
  reddit_client_id: System.get_env("REDDIT_CLIENT_ID"),
  reddit_client_secret: System.get_env("REDDIT_CLIENT_SECRET"),
  google_custom_search_key: System.get_env("GOOGLE_CUSTOM_SEARCH_KEY"),
  google_search_engine_id: System.get_env("GOOGLE_SEARCH_ENGINE_ID")
```

### Environment Variables

Create a `.env` file in the project root:

```bash
# Scholarly APIs
SEMANTIC_SCHOLAR_API_KEY=your_key_here
CROSSREF_API_KEY=your_key_here

# News APIs
NEWSAPI_KEY=your_key_here

# Social/Forum APIs
REDDIT_CLIENT_ID=your_client_id
REDDIT_CLIENT_SECRET=your_client_secret
STACKOVERFLOW_KEY=your_key_here

# Web Search APIs
GOOGLE_CUSTOM_SEARCH_KEY=your_key_here
GOOGLE_SEARCH_ENGINE_ID=your_search_engine_id
BING_SEARCH_KEY=your_key_here
```

## Deployment

Ready to run in production? Check out the [Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

### Building for Production

```bash
# Build assets
mix assets.deploy

# Build release
MIX_ENV=prod mix release
```

## Development Roadmap

- [ ] Integrate Semantic Scholar API for scholarly articles
- [ ] Integrate NewsAPI for news articles
- [ ] Integrate Reddit API for user content
- [ ] Integrate Google Custom Search for web results
- [ ] Add result caching with Redis
- [ ] Implement user accounts and search history
- [ ] Add advanced filtering and sorting options
- [ ] Create saved searches feature
- [ ] Add export functionality (CSV, JSON)
- [ ] Implement rate limiting for API calls

## Testing

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover
```

## Code Formatting

Before committing, ensure code is properly formatted:

```bash
mix format
```

## Learn More

- Official Phoenix website: https://www.phoenixframework.org/
- Phoenix Guides: https://hexdocs.pm/phoenix/overview.html
- Phoenix Docs: https://hexdocs.pm/phoenix
- Phoenix LiveView: https://hexdocs.pm/phoenix_live_view
- Elixir Forum: https://elixirforum.com/c/phoenix-forum

## License

MIT License - See LICENSE file for details
