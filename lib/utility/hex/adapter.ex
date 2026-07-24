defmodule Utility.Hex.Api.Adapter do
  @moduledoc false
  @behaviour :hex_http

  @impl true
  def request(method, uri, req_headers, req_body, _config) do
    {content_type, payload} = deconstruct_body(req_body)
    headers = prepare_headers(req_headers, content_type)
    body = if payload == "", do: nil, else: payload

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

  @impl true
  def request_to_file(_method, _uri, _headers, _body, _target, _config) do
    raise "Utility.Hex.Api.Adapter does not implement request_to_file/6"
  end

  defp deconstruct_body(:undefined), do: {nil, ""}
  defp deconstruct_body(body), do: body
end
