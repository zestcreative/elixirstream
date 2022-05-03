defmodule Utility.ProjectRunner do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def run(pid, command, run_opts \\ []) do
    {timeout, run_opts} = Keyword.pop(run_opts, :timeout, :timer.seconds(5))
    GenServer.call(pid, {:run, command, run_opts}, timeout)
  end

  @impl GenServer
  def init(opts) do
    Process.flag(:trap_exit, true)
    line_counter = :counters.new(1, [:atomics])

    {:ok,
     %{
       port: nil,
       mount: nil,
       command: nil,
       status: nil,
       from: nil,
       line_counter: line_counter,
       opts: opts,
       output: []
     }}
  end

  def output(pid) when is_pid(pid) do
    GenServer.call(pid, :output)
  end

  def output(buffer) when is_list(buffer) do
    buffer |> Enum.reverse() |> Enum.join() |> String.split("\n")
  end

  @impl GenServer
  def handle_call(:output, _from, state) do
    {:reply, output(state.output), state}
  end

  @impl GenServer
  def handle_call({:run, command, run_opts}, from, state) do
    args =
      [Application.get_env(:utility, :docker_bin), "run"]
      |> add_mount(run_opts)
      |> add_command(command, run_opts)

    Logger.info("Running app generator: #{inspect(args)}")

    if broadcaster = state[:opts][:broadcaster] do
      broadcaster.({:progress, "Starting runner", "#{state[:opts][:prefix]}starting"})
      broadcaster.({:progress, "Running: #{command}", "#{state[:opts][:prefix]}starting"})
    end

    port =
      Port.open({:spawn_executable, antizombie()}, [
        :binary,
        :exit_status,
        :stderr_to_stdout,
        args: args
      ])

    {:noreply, %{state | command: Enum.join(args, " "), from: from, port: port}}
  end

  @antizombie "bin/external.sh"
  def antizombie, do: path_for(@antizombie)

  @impl GenServer
  def handle_info({_port, {:data, line}}, state) do
    :counters.add(state.line_counter, 1, 1)

    if broadcaster = state[:opts][:broadcaster],
      do:
        broadcaster.(
          {:progress, line, "#{state[:opts][:prefix]}#{:counters.get(state.line_counter, 1)}"}
        )

    Logger.debug(line)
    {:noreply, %{state | output: [String.replace(line, "\r", "") | state.output]}}
  end

  @impl GenServer
  def handle_info({_port, {:exit_status, status}}, state) do
    prefix = state[:opts][:prefix]

    if status == 0 do
      if broadcaster = state.opts[:broadcaster],
        do: broadcaster.({:progress, "Finished", "#{prefix}finished"})

      if state.from, do: GenServer.reply(state.from, {:ok, output(state.output)})
    else
      if broadcaster = state.opts[:broadcaster],
        do: broadcaster.({:progress, "Finished with error", "#{prefix}finishederror"})

      if state.from, do: GenServer.reply(state.from, {:error, output(state.output)})
    end

    new_state = %{state | status: status}
    Logger.debug("Finished: #{inspect(new_state)}")

    {:noreply, new_state, 500}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp add_mount(cmd, run_opts) do
    if mount = Keyword.get(run_opts, :mount) do
      cmd ++ ["-v", "#{mount}:/app"]
    else
      cmd
    end
  end

  defp add_command(cmd, command, opts) do
    tag = Keyword.get(opts, :tag, "latest")
    cmd ++ ["--rm", "diff-builder:#{tag}", "/bin/bash", "-c", command]
  end

  def path_for(relative_path) do
    if Application.get_env(:utility, :app_env) == :prod do
      relative_path
    else
      Path.join(["rel", "overlays", relative_path])
    end
  end
end
