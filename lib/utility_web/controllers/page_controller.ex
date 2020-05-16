defmodule UtilityWeb.PageController do
  use UtilityWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
