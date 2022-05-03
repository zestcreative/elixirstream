defmodule Utility.ProjectRunnerBuilder do
  @moduledoc """
  Build the docker images that generate applications.
  """
  use GenServer, restart: :transient
  alias Utility.ProjectRunner
  require Logger

  def start_link(opts \\ %{}), do: GenServer.start_link(__MODULE__, opts)

  @runners ["latest", "old", "111", "rails"]
  @impl true
  def init(opts) do
    {runners, opts} = Keyword.pop(opts, :runners, @runners)

    {:ok,
     %{
       status: nil,
       runners: runners,
       current_runner: nil,
       opts: opts,
       output: %{}
     }, {:continue, :startup}}
  end

  @impl GenServer
  def handle_continue(:startup, state) do
    pop_runner(state)
  end

  @impl GenServer
  def handle_info({_port, {:data, line}}, state) do
    Logger.info(line)

    {:noreply,
     update_in(
       state,
       [:output, state.current_runner],
       &[String.replace(line, "\r", "") | &1 || []]
     )}
  end

  @impl GenServer
  def handle_info({_port, {:exit_status, status}}, state) do
    state
    |> update_in([:output, state.current_runner], &(&1 |> Enum.reverse() |> Enum.join("\n")))
    |> Map.put(:current_runner, nil)
    |> Map.put(:status, status)
    |> tap(&Logger.info("Finished: #{inspect(&1)}"))
    |> pop_runner()
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp pop_runner(state) do
    {runner, runners} = List.pop_at(state[:runners], 0)
    state = %{state | current_runner: runner, runners: runners}

    if runner do
      build("Dockerfile.#{runner}", runner)
      {:noreply, state}
    else
      {:stop, :normal, state}
    end
  end

  defp build(dockerfile, tag) do
    {user_id, 0} = System.cmd("id", ["-u"])
    {group_id, 0} = System.cmd("id", ["-g"])
    {user, 0} = System.cmd("whoami", [])
    user = String.trim(user)
    group_id = String.trim(group_id)
    user_id = String.trim(user_id)
    Logger.info("Building runner: #{tag} with #{user} (#{user_id}:#{group_id})")

    args = [
      Application.get_env(:utility, :docker_bin),
      "build",
      "-t",
      "diff-builder:#{tag}",
      "--build-arg",
      "USER_ID=#{user_id}",
      "--build-arg",
      "GROUP_ID=#{group_id}",
      "--build-arg",
      "USER=#{user}",
      "-f",
      ProjectRunner.path_for("diffbuilder/#{dockerfile}"),
      ProjectRunner.path_for("diffbuilder/.")
    ]

    Port.open({:spawn_executable, ProjectRunner.antizombie()}, [
      :binary,
      :exit_status,
      args: args
    ])
  end
end
