defmodule Utility.MixProject do
  use Mix.Project

  def project do
    [
      app: :utility,
      version: String.trim(File.read!("VERSION")),
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        utility: [
          steps: [:assemble, :tar],
          path: "releases/artifacts",
          include_executables_for: [:unix],
          include_erts: true,
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  def application do
    [
      mod: {Utility.Application, []},
      extra_applications: extra_applications(Mix.env())
    ]
  end

  # Specifies which paths to compile per environment.
  defp extra_applications(:test), do: [:logger]
  defp extra_applications(_), do: [:logger, :runtime_tools, :os_mon]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:ansi_to_html, "~> 0.4.0"},
      {:castore, ">= 0.0.0"},
      {:ecto_sql, "~> 3.0"},
      {:etso, "~> 0.1.2"},
      {:gettext, "~> 0.11"},
      {:git_diff, github: "dbernheisel/git_diff", branch: "db-relative-to-rename"},
      # {:git_diff, "~> 0.6.2"},
      {:hackney, "~> 1.15"},
      {:hex_core, "~> 0.7.0"},
      {:jason, "~> 1.1"},
      {:oban, "~> 2.3"},
      {:phoenix, "~> 1.5.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_dashboard, "~> 0.3"},
      {:phoenix_live_view, "~> 0.15"},
      {:plug_cowboy, "~> 2.3"},
      {:postgrex, ">= 0.0.0"},
      {:redix, ">= 0.0.0"},
      {:sentry, "~> 8.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      # Test
      {:floki, ">= 0.0.0", only: :test},
      # Dev
      {:phoenix_live_reload, "~> 1.2", only: :dev}
    ]
  end

  defp aliases do
    [
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      outdated: ["hex.outdated", "cmd npm --prefix assets outdated || true"],
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
