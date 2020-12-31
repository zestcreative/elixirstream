defmodule Utility.GenDiff.Data do
  @known %{
    "phx_new" => %{
      url: "https://hex.pm/packages/phx_new",
      generators: [
        %{
          command: "phx.new",
          docs_url: "https://hexdocs.pm/phx_new/Mix.Tasks.Phx.New.html",
          default_flags: ["my_app"],
          help: "Command is `phoenix.new` prior to version 1.3.0. Not all flags exist on all versions and may result in an error.",
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
      ]
    },
    "phx_gen_auth" => %{
      url: "https://hex.pm/packages/phx_gen_auth",
      generators: [
        %{
          command: "phx.gen.auth",
          docs_url: "https://hexdocs.pm/phx_gen_auth",
          default_flags: ["Accounts", "User", "users"],
          help: "Ran on a default Phoenix 1.5.7 project",
          flags: [
            "--binary-id",
            "--no-binary-id"
          ]
        }
      ]
    },
    "nerves_bootstrap" => %{
      url: "https://hex.pm/packages/nerves_bootstrap",
      generators: [
        %{
          command: "nerves.new",
          docs_url: "https://hexdocs.pm/nerves_bootstrap/Mix.Tasks.Nerves.New.html",
          default_flags: ["my_app"],
          flags: []
        }
      ]
    },
    "scenic_new" => %{
      url: "https://hex.pm/packages/scenic_new",
      generators: [
        %{
          command: "scenic.new",
          docs_url: "https://hexdocs.pm/scenic_new/Mix.Tasks.Scenic.New.html",
          default_flags: ["my_app"],
          flags: []
        },
        %{
          command: "scenic.new.nerves",
          docs_url: "https://hexdocs.pm/scenic_new/Mix.Tasks.Scenic.New.Nerves.html",
          default_flags: ["my_app"],
          flags: []
        },
        %{
          command: "scenic.new.example",
          docs_url: "https://hexdocs.pm/scenic_new/Mix.Tasks.Scenic.New.Example.html",
          default_flags: ["my_app"],
          flags: []
        }
      ]
    }
  }

  def all, do: @known

  def projects(), do: all() |> Map.keys()

  def get_by(project: project) do
    all()[project]
  end

  def get_by(command: command) do
    Enum.find_value(all(), fn {_project, %{generators: generators}} ->
      Enum.find_value(generators, fn generator ->
        generator[:command] == command && generator
      end)
    end)
  end

  def commands_for_project(project) do
    Enum.map(all()[project][:generators] || [], & &1[:command])
  end

  def url_for_project(project) do
    case get_by(project: project) do
      %{url: url} -> url
      _ -> nil
    end
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

  def docs_url_for_command(command) do
    case get_by(command: command) do
      %{docs_url: url} -> url
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
