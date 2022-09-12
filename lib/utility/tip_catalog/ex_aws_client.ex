defmodule Utility.TipCatalog.ExAwsClient do
  @behaviour ExAws.Request.HttpClient
  @client ExAwsFinch

  def request(method, url, body, headers, http_opts) do
    method
    |> Finch.build(url, headers, body)
    |> Finch.request(@client, http_opts)
    |> case do
      {:ok, response} ->
        {:ok, %{status_code: response.status, body: response.body, headers: response.headers}}

      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end
end
