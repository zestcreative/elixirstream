defmodule Utility.Workers.GenerateDiff do
  use Oban.Worker, queue: :builder
  alias Utility.GenDiff.Generator

  @impl Oban.Worker
  def perform(%{args: %{"generator" => params} = _args}) do
    record = hydrate(params)
    broadcaster = make_broadcaster(record)

    with {:error, :not_found} <- Utility.Storage.get(record.project, record.id),
         _ <- broadcaster.({:progress, "Started", "all-started"}),
         :ok <- Utility.ProjectBuilder.diff(record, broadcaster: broadcaster) do
      broadcaster.({:progress, "Finished", "all-finished"})
    else
      {:ok, _stream} ->
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
