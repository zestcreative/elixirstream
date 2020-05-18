defmodule UtilityWeb.DashboardController do
  use UtilityWeb, :controller

  def show(conn, _params) do
    redirect(conn, to: Routes.live_path(conn, UtilityWeb.RegexLive))
  end
end
