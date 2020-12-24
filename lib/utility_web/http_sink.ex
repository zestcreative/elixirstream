defmodule UtilityWeb.HttpSink do
  @topic "sink"

  defstruct [:id, :method, :received_at, :query_string, :body_params, :headers, format: :text]
  @reject_headers ~w[host x-forwarded-for x-forwarded-proto x-real-ip]

  def build(conn) do
    %__MODULE__{
      id: conn |> Plug.Conn.get_resp_header("x-request-id") |> List.first(),
      method: conn.method,
      query_string: conn.query_string,
      headers:
        Enum.reject(conn.req_headers, fn
          {header, _} when header in @reject_headers -> true
          _ -> false
        end),
      received_at: DateTime.utc_now(),
      body_params: conn.body_params
    }
    |> read_body(conn)
  end

  def broadcast(id, payload) do
    Phoenix.PubSub.broadcast(Utility.PubSub, topic_for(id), payload)
  end

  def subscribe(id) do
    Phoenix.PubSub.subscribe(Utility.PubSub, "#{@topic}:#{id}")
  end

  def unsubscribe(nil), do: :ok

  def unsubscribe(id) do
    Phoenix.PubSub.unsubscribe(Utility.PubSub, "#{@topic}:#{id}")
  end

  defp topic_for(id), do: "#{@topic}:#{id}"

  defp read_body(%{body_params: %Plug.Conn.Unfetched{}} = sink, conn) do
    read_body(%{sink | body_params: ""}, Plug.Conn.read_body(conn, length: 1_000_000))
  end

  defp read_body(%{body_params: params} = sink, _conn) when is_map(params) do
    %{sink | format: :json}
  end

  defp read_body(sink, {:ok, body, _conn}) do
    %{sink | body_params: sink.body_params <> body}
  end

  @max_size 5_000_000
  defp read_body(%{body_params: body} = sink, {:more, _, _}) when byte_size(body) > @max_size do
    %{sink | body_params: "Body too large. Maximum size is #{@max_size} bytes"}
  end

  defp read_body(sink, {:more, body, conn}) do
    read_body(
      %{sink | body_params: sink.body_params <> body},
      Plug.Conn.read_body(conn, length: 1_000_000)
    )
  end

  defp read_body(sink, _conn), do: sink
end
