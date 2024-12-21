defmodule Utility.MixProject do
  use Mix.Project

  def project do
    [
      app: :utility,
      version: String.trim(File.read!("VERSION")),
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        utility: [
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
      {:ansi_to_html, "~> 0.6"},
      {:castore, ">= 0.0.0"},
      {:ecto, "~> 3.11.0", override: true},
      {:ecto_sql, "~> 3.11.0", override: true},
      {:etso, "~> 1.0"},
      {:finch, "~> 0.6"},
      {:git_diff, "~> 0.6.3"},
      {:guardian, "~> 2.0"},
      {:hackney, "~> 1.15"},
      {:hex_core, "~> 0.7.0"},
      {:jason, "~> 1.1"},
      {:makeup, "~> 1.0"},
      {:makeup_elixir, "~> 1.0"},
      {:oban, "~> 2.3"},
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:phoenix_live_view, "~> 1.0"},
      {:bandit, ">= 0.6.8"},
      {:postgrex, ">= 0.19.0", override: true},
      {:quarto, "~> 1.0"},
      {:redix, ">= 0.0.0"},
      {:sentry, "~> 10.0"},
      {:sweet_xml, "~> 0.7"},
      {:telemetry, "~> 1.1", override: true},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:ueberauth, "~> 0.10"},
      {:ueberauth_github, "~> 0.8"},
      {:ueberauth_twitter, "~> 0.3"},
      # Test/Dev
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:esbuild, "~> 0.3", runtime: Mix.env() == :dev},
      {:floki, ">= 0.0.0", only: :test},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev}
    ]
  end

  defp aliases do
    [
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      outdated: ["hex.outdated", "cmd npm --prefix assets outdated || true"],
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
