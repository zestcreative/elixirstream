defmodule Utility.Mastodon do
  @moduledoc "Posting tips to Mastodon"

  alias Utility.TipCatalog
  alias Utility.Mastodon.Client
  use UtilityWeb, :verified_routes
  @endpoint UtilityWeb.Endpoint

  def publish(tip) do
    if config()[:publish] do
      with {:ok, tip, file} <- TipCatalog.generate_codeshot(tip),
           {:ok, media_id} <- Client.upload_media(file, description: tip.code),
           {:ok, %{body: %{"id" => fedi_status_id}}} <-
             Client.update_status(status_body(tip), [media_id]) do
        result = TipCatalog.add_fedi_status_id(tip, fedi_status_id)
        File.rm(file)
        result
      end
    else
      {:ok, tip}
    end
  end

  def status_body(tip) do
    []
    |> put_url(tip)
    |> put_contributor(tip)
    |> put_title(tip)
    |> Enum.join()
    |> fill_with_description(tip)
  end

  def put_title(body, %{title: title}), do: [title | body]

  def put_contributor(body, %{contributor: %{name: name, twitter: nil}}),
    do: [" by #{name}" | body]

  def put_contributor(body, %{contributor: %{twitter: twitter}}), do: [" by @#{twitter}" | body]

  def put_url(body, %{id: tip_id}), do: [" ", ~p"/tips/#{tip_id}" | body]

  @status_limit 500
  def fill_with_description(body, %{description: description}) do
    description = "\n\n#{description}"
    taken_chars = String.length(body)
    remaining_chars = @status_limit - taken_chars

    if String.length(description) > remaining_chars do
      truncated = description |> String.split() |> Enum.drop(-1) |> Enum.join(" ")

      if String.last(truncated) == "." do
        body <> "\n\n" <> truncated
      else
        body <> "\n\n" <> truncated <> "..."
      end
    else
      body <> description
    end
  end

  defp config, do: Application.get_env(:utility, __MODULE__)
end
