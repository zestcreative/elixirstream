defmodule Utility.Mastodon.Client do
  require Logger

  @client MastodonFinch
  @base_uri URI.parse("https://hachyderm.io")
  @status_uri URI.merge(@base_uri, "/api/v1/statuses")
  @media_uri URI.merge(@base_uri, "/api/v2/media")

  @doc "https://docs.joinmastodon.org/methods/statuses/#get"
  def get_status(status_id) do
    uri = URI.merge(@status_uri, @status_uri.path <> "/#{status_id}")

    :get
    |> Finch.build(uri, authorize())
    |> Finch.request(@client)
    |> handle_response()
  end

  @doc "https://docs.joinmastodon.org/methods/statuses/#create"
  def update_status(status, media_ids) do
    body =
      [status: status, visibility: "public"]
      |> then(& if media_ids == [], do: &1, else: Keyword.put(&1, :media_ids, media_ids))
      |> URI.encode_query()

    :post
    |> Finch.build(@status_uri, [{"content-type", "application/x-www-form-urlencoded"}] ++ authorize(), body)
    |> Finch.request(@client)
    |> handle_response()
  end

  @doc "https://docs.joinmastodon.org/methods/media/#v2"
  def upload_media(file, opts \\ [])
  def upload_media(nil, _opts), do: {:ok, nil}
  def upload_media(file, opts) do
    body =
      [file: File.read!(file)]
      |> then(& if opts[:description], do: Map.put(&1, :description, opts[:description]), else: &1)
      |> URI.encode_query()

    :post
    |> Finch.build(@media_uri, [{"content-type", "application/x-www-form-urlencoded"}] ++ authorize(), body)
    |> Finch.request(@client)
    |> handle_response()
    |> case do
      {:ok, %{body: %{"id" => media_id}}} -> {:ok, media_id}
      error -> error
    end
  end

  def authorize() do
    token =
      :utility
      |> Application.get_env(Utility.Mastodon.Client)
      |> Keyword.fetch!(:access_token)

    [{"Authorization", "Bearer #{token}"}]
  end

  defp handle_response({:ok, %{status: code, headers: headers, body: body} = response})
       when code in 200..299 do
    with [header] <- Plug.Conn.get_resp_header(%Plug.Conn{resp_headers: headers}, "content-type"),
         true <- "application/json" in String.split(header, ";") do
      {:ok, %{response | body: Jason.decode!(body)}}
    else
      _ -> response
    end
  end

  defp handle_response({:ok, response}), do: {:error, response}
  defp handle_response(error), do: error
end
