defmodule ScholarlySearch.Repo do
  use Ecto.Repo,
    otp_app: :scholarly_search,
    adapter: Ecto.Adapters.Postgres
end
