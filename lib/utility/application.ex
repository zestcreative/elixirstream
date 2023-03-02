defmodule Utility.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        # Start the Telemetry supervisor
        UtilityWeb.Telemetry,
        Utility.Repo,
        Utility.PackageRepo,
        # Start the PubSub system
        {Phoenix.PubSub, name: Utility.PubSub},
        # Start the Endpoint (http/https)
        UtilityWeb.Endpoint,
        Utility.Redix,
        {Oban, oban_config()}
        # Start a worker by calling: Utility.Worker.start_link(arg)
        # {Utility.Worker, arg}
      ]
      |> project_runner_builder()

    events = [[:oban, :job, :exception], [:oban, :circuit, :trip]]
    :ok = Oban.Telemetry.attach_default_logger()

    :telemetry.attach_many(
      "oban-logger",
      events,
      &Utility.Workers.ErrorHandler.handle_event/4,
      []
    )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Utility.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    UtilityWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def oban_config do
    Application.get_env(:utility, Oban)
  end

  if Mix.env() == :test do
    defp project_runner_builder(apps) do
      apps
    end
  else
    defp project_runner_builder(apps) do
      apps ++
        [
          Utility.Package.Updater,
          Utility.ProjectRunnerBuilder,
          Utility.GenDiff.PruneMainBranchCache
        ]
    end
  end
end
