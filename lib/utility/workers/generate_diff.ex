defmodule Utility.Workers.GenerateDiff do
  use Oban.Worker,
    queue: :builder,
    unique: [period: :infinity]

  @impl Oban.Worker
  def perform(%{args: %{} = _args}) do
    :ok
    # output
  end
end
