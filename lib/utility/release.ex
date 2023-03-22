defmodule Utility.Release do
  @moduledoc """
  This is a module that is involved directly with Mix Release shell commands. It's similar to a Mix
  task, but it's not. Instead, the app is already running, and this opens the running
  application and can execute any of these functions directly while the app still runs.

  This is primarily used to migrate, seed, and rollback the database.
  """
  @app :utility

  @doc """
  Migrate the database. Defaults to migrating to the latest, ie `[all: true]`
  Also accepts `[step: 1]`, or `[to: 20200118045751]`
  """
  def migrate(opts \\ [all: true]) do
    for repo <- repos(), do: run_migrations_for(repo, opts)
  end

  @doc """
  Rollback the database. Defaults to rolling back one step.
  Also accepts `[to: 20200118045751]`
  """
  def rollback(opts \\ [step: 1]) do
    for repo <- repos(), do: run_rollbacks_for(repo, opts)
  end

  def seed do
    for repo <- repos(), do: run_seeds_for(repo)
  end

  if Mix.env() == :dev do
    @excluded_tables ~w[schema_migrations]

    def truncate(tables \\ nil) do
      alias Ecto.Adapters.SQL

      query = """
      SELECT tablename from "pg_tables"
      WHERE schemaname = 'public'
        AND tablename NOT IN (#{@excluded_tables |> Enum.map_join(", ", &"'#{&1}'")});
      """

      for repo <- repos() do
        (tables || repo |> SQL.query(query) |> elem(1) |> Map.get(:rows))
        |> List.flatten()
        |> Enum.each(fn table -> SQL.query(repo, "TRUNCATE #{table} CASCADE;") end)
      end
    end
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp run_migrations_for(repo, opts) do
    app = Keyword.get(repo.config, :otp_app)
    IO.puts("Running migrations for #{app}...")
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, opts))
  end

  defp run_rollbacks_for(repo, opts) do
    app = Keyword.get(repo.config, :otp_app)
    IO.puts("Running rollbacks for #{app}...")
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, opts))
  end

  defp run_seeds_for(repo) do
    IO.puts("Running seed script...")
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &seeder/1)
  end

  defp seeder(repo, seed_file \\ "seeds.exs") do
    seed_script = priv_path_for(repo, seed_file)
    Code.eval_file(seed_script)
  end

  defp priv_path_for(repo, filename) do
    repo_underscore =
      repo
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    Path.join(["#{:code.priv_dir(@app)}", repo_underscore, filename])
  end
end
