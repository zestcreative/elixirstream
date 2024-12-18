defmodule Utility.ProjectRunnerBuilder do
  @moduledoc """
  Build the docker images that generate applications.
  """
  use GenServer, restart: :transient
  alias Utility.ProjectRunner
  require Logger

  def start_link(opts \\ %{}), do: GenServer.start_link(__MODULE__, opts)

  @runners ["13", "111", "112", "114", "117", "rails27", "rails32"]
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
    build_a_runner(state)
  end

  @impl GenServer
  def handle_info({_port, {:data, line}}, state) do
    Logger.debug(line)

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
    |> update_in([:output, state.current_runner], fn output ->
      if output do
        output |> Enum.reverse() |> Enum.join("\n")
      end
    end)
    |> Map.put(:current_runner, nil)
    |> Map.put(:status, status)
    |> tap(&Logger.info("Finished: #{inspect(&1)}"))
    |> build_a_runner()
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp build_a_runner(state) do
    {runner, runners} = List.pop_at(state[:runners], 0)
    state = %{state | current_runner: runner, runners: runners}

    if runner do
      build("Dockerfile.#{runner}", runner)
      {:noreply, state}
    else
      {:stop, :normal, state}
    end
  end

  def build(dockerfile, tag) do
    group_id = group_id()
    user_id = user_id()
    user = user()
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

  defp user_id do
    {user_id, 0} = System.cmd("id", ["-u"])
    String.trim(user_id)
  end

  defp user do
    {user, 0} = System.cmd("whoami", [])
    String.trim(user)
  end

  defp group_id do
    case :os.type() do
      {:unix, :darwin} ->
        501

      _ ->
        {group_id, 0} = System.cmd("id", ["-g"])
        String.trim(group_id)
    end
  end
end
