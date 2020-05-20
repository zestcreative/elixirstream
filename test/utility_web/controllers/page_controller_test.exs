defmodule UtilityWeb.PageControllerTest do
  use UtilityWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert redirected_to(conn) =~ Routes.live_path(conn, UtilityWeb.RegexLive)
  end
end
