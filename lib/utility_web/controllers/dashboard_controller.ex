defmodule UtilityWeb.DashboardController do
  use UtilityWeb, :controller

  def show(conn, _params) do
    render(conn, "show.html")
  end
end
