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

- **Scholarly Articles**: ✅ **Integrated with Semantic Scholar API** (CrossRef, PubMed, arXiv ready for integration)
- **News Articles**: Ready for integration with NewsAPI, Google News, Reuters
- **User Content**: Ready for integration with Reddit, Stack Exchange, Hacker News
- **Web Results**: Ready for integration with Google Custom Search, Bing, DuckDuckGo

#### Semantic Scholar Integration

The scholarly articles module now supports real API integration with Semantic Scholar. By default, it uses mock data for development, but you can enable the real API:

1. Set the environment variable: `export USE_REAL_API=true`
2. (Optional) Add API key for higher rate limits: `export SEMANTIC_SCHOLAR_API_KEY=your_key_here`
3. The module automatically falls back to mock data if the API fails

See the [API Configuration](#api-keys) section below for details.

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

#### Semantic Scholar API (Currently Integrated)

The Semantic Scholar API is now integrated and can be enabled via environment variables:

```bash
# Enable real API (default: false, uses mock data)
export USE_REAL_API=true

# Optional: Add API key for higher rate limits
# Free tier available without key
# Get your key at: https://www.semanticscholar.org/product/api
export SEMANTIC_SCHOLAR_API_KEY=your_key_here
```

**Rate Limits:**
- **Without API key**: 100 requests per 5 minutes
- **With API key**: Higher limits (see Semantic Scholar documentation)

**Features:**
- Automatic fallback to mock data on API failure
- Comprehensive error handling and logging
- Real-time scholarly article search with metadata (citations, authors, venue, year)

#### Other APIs (Ready for Integration)

To integrate additional search APIs in the future, you can add configuration to `config/runtime.exs`:

```elixir
config :scholarly_search,
  # News APIs
  newsapi_key: System.get_env("NEWSAPI_KEY"),

  # Social/Forum APIs
  reddit_client_id: System.get_env("REDDIT_CLIENT_ID"),
  reddit_client_secret: System.get_env("REDDIT_CLIENT_SECRET"),

  # Web Search APIs
  google_custom_search_key: System.get_env("GOOGLE_CUSTOM_SEARCH_KEY"),
  google_search_engine_id: System.get_env("GOOGLE_SEARCH_ENGINE_ID")
```

### Environment Variables

A `.env.example` file is provided. Copy it to `.env` and update with your actual values:

```bash
cp .env.example .env
```

**Note:** The `.env` file is in `.gitignore` and should never be committed to version control.

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
