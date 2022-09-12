defmodule Utility.Workers.PublishTip do
  @moduledoc false
  use Oban.Worker, queue: :publish_tip
  alias Utility.TipCatalog
  alias Utility.Twitter

  @impl Oban.Worker
  def perform(%{args: %{"tip_id" => tip_id}}) do
    case TipCatalog.find_tip(tip_id) do
      %{twitter_status_id: nil} = tip ->
        Twitter.publish(tip)

      _ ->
        :ok
    end
  end
end
