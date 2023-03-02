defmodule Utility.GenDiff.PruneMainBranchCache do
  use GenServer
  require Logger
  alias Utility.GenDiff.Storage

  @default_prune_every :timer.hours(12)

  def start_link(opts \\ []) do
    {prune_every, opts} = Keyword.pop(opts, :prune_every, @default_prune_every)
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %{prune_every: prune_every, opts: opts}, name: name)
  end

  def prune(pid \\ __MODULE__) do
    GenServer.call(pid, :prune, :infinity)
  end

  @impl GenServer
  def init(state) do
    state = Map.put(state, :timer, schedule_prune(state[:prune_every]))
    {:ok, state, {:continue, :startup}}
  end

  @impl GenServer
  def handle_continue(:startup, state) do
    handle_call(:prune, self(), state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:prune, _from, %{timer: timer} = state) do
    Process.cancel_timer(timer)
    {:reply, do_prune(), %{state | timer: schedule_prune(state[:prune_every])}}
  end

  defp do_prune() do
    Logger.info("PruneMainBranchCache: Starting to prune")

    Utility.GenDiff.Data.projects()
    |> Enum.map(fn project ->
      {project, list_branch(project, "master") ++ list_branch(project, "main")}
    end)
  end

  defp list_branch(project, branch) do
    project
    |> Storage.list("*#{branch}*")
    |> Enum.map(fn cached_diff ->
      Logger.info("PruneMainBranchCache: pruning #{cached_diff}")
      Storage.delete(cached_diff)
      cached_diff
    end)
  end

  defp schedule_prune(prune_every) do
    Process.send_after(self(), :prune, prune_every)
  end
end
