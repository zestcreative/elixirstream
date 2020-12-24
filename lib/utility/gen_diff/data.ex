defmodule Utility.GenDiff.Data do
  @known %{
    "phx_new" => [
      %{
        command: "phx.new",
        default_flags: ["my_app"],
        help: "Command is `phoenix.new` prior to 1.3.0. Not all flags exist on all versions.",
        flags: [
          "--binary-id",
          "--database=mssql",
          "--database=mysql",
          "--database=postgres",
          "--live",
          "--no-dashboard",
          "--no-ecto",
          "--no-gettext",
          "--no-html",
          "--no-webpack",
          "--umbrella"
        ]
      }
    ],
    "nerves_bootstrap" => [
      %{
        command: "nerves.new",
        default_flags: ["my_app"],
        flags: []
      }
    ],
    "scenic_new" => [
      %{
        command: "scenic.new",
        default_flags: ["my_app"],
        flags: []
      }
    ]
  }

  def all, do: @known

  def projects(), do: all() |> Map.keys()

  def get_by(command: command) do
    Enum.find_value(Map.values(all()), fn generators ->
      Enum.find(generators, fn generator ->
        generator[:command] == command
      end)
    end)
  end

  def commands_for_project(project) do
    Enum.map(all()[project] || [], & &1[:command])
  end

  def flags_for_command(command) do
    case get_by(command: command) do
      %{flags: flags} -> flags
      _ -> []
    end
  end

  def help_for_command(command) do
    case get_by(command: command) do
      %{help: help} -> help
      _ -> nil
    end
  end

  def default_flags_for_command(command) do
    case get_by(command: command) do
      %{default_flags: default_flags} -> default_flags
      _ -> []
    end
  end

  @phoenix_new_versions ~w[1.0.0 1.0.1 1.0.2 1.0.3 1.0.4 1.1.0 1.1.1 1.1.2 1.1.3 1.1.4 1.1.5 1.1.6
    1.1.9 1.2.0 1.2.1 1.2.4 1.2.5]
  @phx_new_versions ~w[1.3.0 1.3.1 1.3.2 1.3.3 1.3.4]
  def versions_for_project("phx_new") do
    @phoenix_new_versions ++ @phx_new_versions ++ get_hex_versions("phx_new")
  end

  def versions_for_project(project) do
    get_hex_versions(project)
  end

  def get_hex_versions(project) do
    case Utility.PackageRepo.get_by(Utility.Hex.Package, name: project) do
      %{versions: versions} -> versions
      _ -> []
    end
  end
end
