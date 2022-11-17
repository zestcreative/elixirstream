defmodule Utility.Twitter do
  alias Utility.TipCatalog
  alias Utility.Twitter.Client
  use UtilityWeb, :verified_routes
  @endpoint UtilityWeb.Endpoint

  def get_status(%{twitter_status_id: nil}), do: {:error, :no_tweet}

  def get_status(%{twitter_status_id: tweet_id}) do
    case Client.get_tweet(tweet_id) do
      {:ok, %{body: %{"data" => data}}} -> {:ok, data}
      {:ok, %{body: %{"errors" => errors}}} -> {:error, errors}
      {:error, _} = error -> error
    end
  end

  def publish(tip) do
    if config()[:publish] do
      with {:ok, tip, file} <- TipCatalog.generate_codeshot(tip),
           {:ok, media_id} <-
             Client.upload_media(file, filename: url_safe(tip.title) <> Path.extname(file)),
           {:ok, %{body: %{"id_str" => twitter_status_id}}} <-
             Client.update_status(tweet_body(tip), [media_id]) do
        TipCatalog.add_twitter_status_id(tip, twitter_status_id)
      end
    else
      {:ok, tip}
    end
  end

  defp url_safe(string) do
    string = string |> String.replace(" ", "-") |> String.downcase()
    Regex.replace(~r/[^a-zA-Z0-9_-]/, string, "")
  end

  def tweet_body(tip) do
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

  @tweet_limit 280
  def fill_with_description(body, %{description: description}) do
    description = "\n\n#{description}"
    taken_chars = String.length(body)
    remaining_chars = @tweet_limit - taken_chars

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
