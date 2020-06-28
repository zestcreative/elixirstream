defmodule UtilityWeb.PageController do
  use UtilityWeb, :controller

  def show(conn, _params) do
    redirect(conn, to: Routes.live_path(conn, UtilityWeb.RegexLive))
  end

  def about(conn, _params) do
    render(conn, "about.html")
  end
end
