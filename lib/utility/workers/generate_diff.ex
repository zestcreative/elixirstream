defmodule Utility.Workers.GenerateDiff do
  @moduledoc false
  use Oban.Worker, queue: :builder
  alias Utility.GenDiff.Generator
  alias Utility.GenDiff.Storage

  @impl Oban.Worker
  def perform(%{args: %{"generator" => params} = _args}) do
    record = hydrate(params)
    broadcaster = make_broadcaster(record)

    # Guard on the patch: it's written together with the HTML by ProjectBuilder.diff,
    # so its presence means a fully-built diff. (Diffs cached before the patch existed
    # will rebuild, which regenerates both artifacts.)
    with {:error, :not_found} <- Storage.get_patch(record),
         _ <- broadcaster.({:progress, "Started", "all-started"}),
         :ok <- Utility.ProjectBuilder.diff(record, broadcaster: broadcaster) do
      broadcaster.({:progress, "Finished", "all-finished"})
    else
      {:ok, _cached} ->
        broadcaster.({:progress, "Finished", "all-finished"})

      {:error, _} ->
        broadcaster.({:progress, "Finished", "all-finished-error"})
    end
  end

  def hydrate(params) do
    case Generator.apply(params) do
      {:ok, record} -> record
      error -> raise(error)
    end
  end

  def make_broadcaster(record) do
    topic = "hexgen:progress:#{record.project}:#{record.id}"

    fn payload ->
      Phoenix.PubSub.broadcast(Utility.PubSub, topic, payload)
    end
  end
end
