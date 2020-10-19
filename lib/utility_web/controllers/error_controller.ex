defmodule UtilityWeb.Controllers.ErrorController do
  use UtilityWeb, :controller

  def call(conn, _) do
    conn
    |> put_status(:unsupported)
    |> put_view(UtilityWeb.ErrorView)
    |> render("415.html")
  end
end
