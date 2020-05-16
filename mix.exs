defmodule Utility.MixProject do
  use Mix.Project

  def project do
    [
      app: :utility,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Utility.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:phoenix, "~> 1.5.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto, "~> 3.0"},
      {:phoenix_live_dashboard, "~> 0.2.0"},
      {:phoenix_live_view, "~> 0.12.0"},
      {:plug_cowboy, "~> 2.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:vapor, ">= 0.6.0"},
      {:redix, ">= 0.0.0"},
      {:castore, ">= 0.0.0"},
      # Test
      {:floki, ">= 0.0.0", only: :test},
      # Dev
      {:phoenix_live_reload, "~> 1.2", only: :dev}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"]
    ]
  end
end
