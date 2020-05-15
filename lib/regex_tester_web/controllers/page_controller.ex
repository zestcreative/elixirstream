defmodule RegexTesterWeb.PageController do
  use RegexTesterWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
