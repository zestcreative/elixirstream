defmodule Utility.Twitter.Client do
  alias Utility.Twitter.Multipart
  require Logger

  @client TwitterFinch

  @base_uri URI.parse("https://api.twitter.com")
  @update_status_uri URI.merge(@base_uri, "/1.1/statuses/update.json")
  @get_tweet_uri URI.merge(@base_uri, "/2/tweets/")

  @upload_uri URI.parse("https://upload.twitter.com")
  @upload_media_uri URI.merge(@upload_uri, "/1.1/media/upload.json")

  @chunk_size 1_000_000

  def get_tweet(status_id) do
    uri = %URI{
      URI.merge(@get_tweet_uri, status_id)
      | query: URI.encode_query(%{"tweet.fields" => "public_metrics"})
    }

    :get
    |> Finch.build(uri)
    |> authorize_request()
    |> Finch.request(@client)
    |> handle_response()
  end

  def update_status(status, media_ids) do
    uri = %URI{
      @update_status_uri
      | query:
          URI.encode_query(
            status: status,
            media_ids: media_ids |> List.wrap() |> Enum.map_join(",", &to_string/1),
            trim_user: 1
          )
    }

    :post
    |> Finch.build(uri)
    |> authorize_request()
    |> Finch.request(@client)
    |> handle_response()
  end

  def upload_media(file, opts \\ [])
  def upload_media(nil, _opts), do: {:ok, nil}

  def upload_media(file, opts) do
    with {:ok, media_id} when is_binary(media_id) <- init_upload(file, opts),
         {:ok, _upload_response} <- upload_chunks(file, media_id, opts),
         {:ok, _finalize_response} <- finalize_upload(media_id) do
      {:ok, media_id}
    end
  end

  defp init_upload(file, opts) do
    %{size: size} = File.stat!(file)
    content_type = Keyword.get(opts, :content_type, MIME.from_path(file))

    uri = %URI{
      @upload_media_uri
      | query:
          URI.encode_query(
            command: "INIT",
            media_type: content_type,
            total_bytes: size
          )
    }

    :post
    |> Finch.build(uri)
    |> authorize_request(query: true)
    |> Finch.request(@client)
    |> handle_response()
    |> case do
      {:ok, %{body: %{"media_id_string" => media_id}}} -> {:ok, media_id}
      error -> error
    end
  end

  defp upload_chunks(file, media_id, opts) do
    filename = Keyword.get(opts, :filename, Path.basename(file))

    file
    |> File.stream!([:read], @chunk_size)
    |> Stream.with_index()
    |> Enum.reduce_while([], fn {chunk, i}, acc ->
      case upload_chunk(chunk, media_id, filename, to_string(i)) do
        {:ok, %{status: status} = response} when status in 200..299 ->
          {:cont, [response | acc]}

        {:ok, error} ->
          {:halt, {:error, error}}

        error ->
          {:halt, error}
      end
    end)
    |> case do
      ok when is_list(ok) ->
        {:ok, ok}

      {:error, error} ->
        Logger.error("Upload Chunk Error: #{inspect(error)}")
        error
    end
  end

  defp upload_chunk(chunk, media_id, filename, segment) do
    uri = %URI{
      @upload_media_uri
      | query:
          URI.encode_query(
            command: "APPEND",
            media_id: media_id,
            segment_index: segment
          )
    }

    mp =
      Multipart.new()
      |> Multipart.add_field("command", "APPEND")
      |> Multipart.add_field("media_id", media_id)
      |> Multipart.add_field("segment_index", segment)
      |> Multipart.add_file_content(chunk, filename,
        name: "media",
        headers: [{"content-type", "application/octet-stream"}]
      )

    body = mp |> Multipart.body() |> Enum.to_list()

    :post
    |> Finch.build(
      uri,
      [{"Content-Type", "multipart/form-data, boundary=\"#{mp.boundary}\""}],
      body
    )
    |> authorize_request(query: true)
    |> Finch.request(@client)
  end

  defp finalize_upload(media_id) do
    uri = %URI{
      @upload_media_uri
      | query: URI.encode_query(command: "FINALIZE", media_id: media_id)
    }

    :post
    |> Finch.build(uri)
    |> authorize_request(query: true)
    |> Finch.request(@client)
    |> handle_response()
  end

  defp authorize_request(request, opts \\ []) do
    credentials =
      :utility
      |> Application.get_env(Utility.Twitter.Client)
      |> OAuther.credentials()

    if Keyword.get(opts, :query, false) do
      params = URI.query_decoder(request.query || "") |> Enum.to_list()
      auth = OAuther.sign(request.method, uri_from_request(request), params, credentials)
      %{request | query: URI.encode_query(auth ++ params)}
    else
      auth = OAuther.sign(request.method, uri_from_request(request), [], credentials)
      {auth_headers, _req_headers} = OAuther.header(auth)
      %{request | headers: [auth_headers] ++ request.headers}
    end
  end

  defp uri_from_request(request) do
    URI
    |> struct(Map.from_struct(request))
    |> Map.update!(:scheme, fn v -> to_string(v) end)
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
