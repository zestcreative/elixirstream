defmodule Utility.Hex.Api.Adapter do
  @moduledoc false
  @behaviour :hex_http

  @impl true
  def request(method, uri, req_headers, req_body, _config) do
    {content_type, payload} = deconstruct_body(req_body)
    headers = prepare_headers(req_headers, content_type)
    body = if payload == "", do: nil, else: payload

    # ponytail: no redirect-following (hackney had follow_redirect); repo.hex.pm
    # serves package metadata as direct 200s. Add manual 3xx handling if that changes.
    case Finch.request(Finch.build(method, uri, headers, body), Utility.Finch) do
      {:ok, %Finch.Response{status: status, headers: resp_headers, body: resp_body}} ->
        # :hex_core expects headers to be a Map
        {:ok, {status, Map.new(resp_headers), resp_body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp prepare_headers(req_headers, content_type) do
    if content_type do
      Map.put(req_headers, "content-type", content_type)
    else
      req_headers
    end
    |> Enum.to_list()
  end

  # ponytail: hex_core 0.15+ added this callback for streaming tarball/docs
  # downloads to disk. We only fetch package metadata, so it's never called.
  @impl true
  def request_to_file(_method, _uri, _headers, _body, _target, _config) do
    raise "Utility.Hex.Api.Adapter does not implement request_to_file/6"
  end

  defp deconstruct_body(:undefined), do: {nil, ""}
  defp deconstruct_body(body), do: body
end
