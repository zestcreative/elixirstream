defmodule Utility.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Attach the Sentry :logger handler configured in config/config.exs.
    Logger.add_handlers(:utility)

    children =
      [
        # Start the Telemetry supervisor
        UtilityWeb.Telemetry,
        # HTTP client pool for the Hex API adapter (lib/utility/hex/adapter.ex)
        {Finch, name: Utility.Finch},
        Utility.Repo,
        Utility.PackageRepo,
        # Start the PubSub system
        {Phoenix.PubSub, name: Utility.PubSub},
        # Start the Endpoint (http/https)
        UtilityWeb.Endpoint,
        {Oban, oban_config()}
        # Start a worker by calling: Utility.Worker.start_link(arg)
        # {Utility.Worker, arg}
      ]
      |> Enum.concat(cache_children())
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

  # Start the DETS cache owner only when it's the configured cache impl (dev/prod).
  # In test the cache is Utility.Test.MockCache, which needs no owner process.
  defp cache_children do
    case Application.get_env(:utility, :cache) do
      Utility.Cache.Dets -> [Utility.Cache.Dets]
      _ -> []
    end
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
          Utility.GenDiff.PruneMainBranchCache,
          # One-shot: warm the on-disk changelog cache once package versions are loaded.
          {Task, &Utility.GenDiff.Changelog.warm_on_boot/0}
        ]
    end
  end
end
