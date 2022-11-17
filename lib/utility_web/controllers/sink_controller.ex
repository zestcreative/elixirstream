defmodule UtilityWeb.SinkController do
  use UtilityWeb, :controller
  alias UtilityWeb.HTTPSink

  def any(conn, %{"foo_sink_id" => id}) when byte_size(id) == 36 do
    start = System.monotonic_time()
    HTTPSink.broadcast(id, HTTPSink.build(conn))

    :telemetry.execute(
      [:utility, :sink, :build],
      %{duration: System.monotonic_time() - start},
      conn
    )

    conn
    |> put_status(200)
    |> text("See sink at #{~p"/sink/view/#{id}"}\n")
  end

  def any(conn, _params) do
    conn
    |> put_status(400)
    |> put_view(UtilityWeb.ErrorHTML)
    |> render("400.html")
  end
end
