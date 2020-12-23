defmodule Utility.Builder do
  use GenServer
  @antizombie "./bin/external.sh"
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, %{})
  end

  def build_builder() do
    {:ok, pid} = start_link()
    GenServer.call(pid, :build_builder)
  end

  @impl GenServer
  def init(_args) do
    Process.flag(:trap_exit, true)
    {:ok, %{port: nil, status: nil, output: []}}
  end

  def output(pid) do
    GenServer.call(pid, :output)
  end

  @impl GenServer
  def handle_call(:output, _from, state) do
    {:reply, state.output |> Enum.reverse() |> Enum.join() |> String.split("\n"), state}
  end

  @impl GenServer
  def handle_call(:build_builder, _from, state) do
    port =
      Port.open({:spawn_executable, @antizombie}, [
        :binary,
        :exit_status,
        args: [Application.get_env(:utility, :docker_bin), "build", "-t", "diff-builder:latest", "-f", "diffbuilder/Dockerfile", "diffbuilder/."]
      ])

    {:noreply, %{state | port: port}}
  end

  @impl GenServer
  def handle_info({_port, {:data, line}}, state) do
    {:noreply, %{state | output: [String.replace(line, "\r", "") | state.output]}}
  end

  @impl GenServer
  def handle_info({_port, {:exit_status, status}}, state) do
    {:noreply, %{state | status: status}, 500}
  end

  def handle_info(_msg, state), do: {:noreply, state}
end
