defmodule UtilityWeb.PageControllerTest do
  use UtilityWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert redirected_to(conn) =~ Routes.regex_path(conn, :new)
  end
end
