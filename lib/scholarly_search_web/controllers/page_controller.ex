defmodule ScholarlySearchWeb.PageController do
  use ScholarlySearchWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
