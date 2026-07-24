defmodule UtilityWeb.GenDiffLiveTest do
  use UtilityWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  @route "/gendiff"

  test "commands populate after selecting a project", %{conn: conn} do
    {:ok, view, _html} = live(conn, @route)

    html =
      view
      |> form("#gen-diff", generator: %{project: "credo"})
      |> render_change()

    assert html =~ "credo.gen.config"
  end
end
