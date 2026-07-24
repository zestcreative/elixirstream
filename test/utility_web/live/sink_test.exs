defmodule UtilityWeb.SinkLiveTest do
  use UtilityWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "mounts and renders the sink view (streams init)", %{conn: conn} do
    # /sink redirects to a generated /sink/view/:id
    assert {:error, {:live_redirect, %{to: "/sink/view/" <> _}}} = live(conn, "/sink")

    {:ok, _view, html} = live(conn, "/sink/view/#{Ecto.UUID.generate()}")
    assert html =~ ~s(id="requests")
  end
end
