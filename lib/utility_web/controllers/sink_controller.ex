defmodule UtilityWeb.SinkController do
  use UtilityWeb, :controller
  alias UtilityWeb.{HttpSink, SinkLive}

  action_fallback ErrorController

  def any(conn, %{"foo_sink_id" => id}) when byte_size(id) == 36 do
    start = System.monotonic_time()
    HttpSink.broadcast(id, HttpSink.build(conn))
    :telemetry.execute(
      [:utility, :sink, :build],
      %{duration: System.monotonic_time() - start},
      conn
    )

    conn
    |> put_status(200)
    |> text("See sink at #{Routes.live_url(conn, SinkLive, id)}")
  end
end
