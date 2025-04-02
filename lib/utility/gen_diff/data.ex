defmodule Utility.GenDiff.Data do
  @moduledoc """
  Hard-coded data for supported projects. Largely to provide a safe known source
  of variables to run in docker containers.
  """
  @known %{
    "phx_new" => %{
      url: "https://hex.pm/packages/phx_new",
      source: :hex,
      generators: [
        %{
          command: "phx.new",
          docs_url: "https://hexdocs.pm/phx_new/Mix.Tasks.Phx.New.html",
          default_flags: ["my_app"],
          help:
            "Command is `phoenix.new` prior to version 1.3.0. Not all flags exist on all versions and may result in an error or be ignored.",
          flags: [
            {"--binary-id", [from: "1.0.0"]},
            {"--adapter=cowboy", [from: "1.7.8"]},
            {"--adapter=bandit", [from: "1.7.8"]},
            {"--database=mongodb", [from: "1.0.0", until: "1.3.3"]},
            {"--database=mssql", [from: "1.0.0"]},
            {"--database=mysql", [from: "1.0.0"]},
            {"--database=postgres", [from: "1.0.0"]},
            {"--database=sqlite", [from: "1.0.0"]},
            {"--database=sqlite3", [from: "1.6.0"]},
            {"--live", [from: "1.5.0", until: "1.6.0"]},
            {"--no-assets", [from: "1.6.0"]},
            {"--no-brunch", [from: "1.0.0", until: "1.4.0"]},
            {"--no-dashboard", [from: "1.5.0"]},
            {"--no-ecto", [from: "1.0.0"]},
            {"--no-esbuild", [from: "1.7.2"]},
            {"--no-gettext", [from: "1.4.12"]},
            {"--no-html", [from: "1.0.0"]},
            {"--no-live", [from: "1.6.0"]},
            {"--no-mailer", [from: "1.6.0"]},
            {"--no-tailwind", [from: "1.7.2"]},
            {"--no-webpack", [from: "1.4.0", until: "1.6.0"]},
            {"--umbrella", [from: "1.3.0"]}
          ]
        },
        %{
          command: "phx.gen.auth",
          docs_url: "https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Auth.html",
          default_flags: ["Accounts", "User", "users"],
          help:
            "phx.gen.auth used to be distributed separately as phx_gen_auth, but was merged into Phoenix in 1.6",
          flags: [
            {"--live", [from: "1.7.0-rc.0"]},
            {"--no-live", [from: "1.7.0-rc.0"]},
            {"--binary-id", [from: "1.6.0"]},
            {"--no-binary-id", [from: "1.6.0"]},
            {"--hashing-lib=bcrypt", [from: "1.6.0"]},
            {"--hashing-lib=pbkdf2", [from: "1.6.0"]},
            {"--hashing-lib=argon2", [from: "1.6.0"]}
          ]
        }
      ]
    },
    "phx_gen_auth" => %{
      url: "https://hex.pm/packages/phx_gen_auth",
      source: :hex,
      generators: [
        %{
          command: "phx.gen.auth",
          docs_url: "https://hexdocs.pm/phx_gen_auth",
          default_flags: ["Accounts", "User", "users"],
          help:
            "Ran on a default Phoenix 1.5.7 project. You might consider using phx_new instead.",
          flags: [
            {"--binary-id", [from: "0.1.0"]},
            {"--no-binary-id", [from: "0.1.0"]},
            {"--hashing-lib=bcrypt", [from: "0.7.0"]},
            {"--hashing-lib=pbkdf2", [from: "0.7.0"]},
            {"--hashing-lib=argon2", [from: "0.7.0"]}
          ]
        }
      ]
    },
    "credo" => %{
      url: "https://hexdocs.pm/credo",
      source: :hex,
      generators: [
        %{
          command: "credo.gen.config",
          since: "1.0.0-rc.1",
          docs_url: "https://hexdocs.pm/credo/config_file.html",
          default_flags: [],
          flags: []
        }
      ]
    },
    "nerves_bootstrap" => %{
      url: "https://hex.pm/packages/nerves_bootstrap",
      source: :hex,
      generators: [
        %{
          command: "nerves.new",
          since: "1.0.0-rc1",
          docs_url: "https://hexdocs.pm/nerves_bootstrap/Mix.Tasks.Nerves.New.html",
          default_flags: ["my_app"],
          flags: []
        }
      ]
    },
    "scenic_new" => %{
      url: "https://hex.pm/packages/scenic_new",
      source: :hex,
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
    },
    "surface" => %{
      url: "https://hex.pm/packages/surface",
      source: :hex,
      generators: [
        %{
          command: "surface.init",
          since: "0.6.0",
          docs_url: "https://hexdocs.pm/surface/Mix.Tasks.Surface.Init.html",
          default_flags: [
            {"--yes", [from: "0.6.0"]},
            {"--no-install", [from: "0.8.0"]},
            {"--no-dep-install", [from: "0.6.0", until: "0.8.0"]}
          ],
          help:
            "Ran on Phoenix 1.7.7 project when version >= 0.10.0 and Phoenix 1.6.16 on prior versions, main also runs on Phoenix main.",
          flags: [
            {"--catalogue", [from: "0.6.0"]},
            {"--demo", [from: "0.6.0"]},
            {"--layouts", [from: "0.8.0"]},
            {"--no-error-tag", [from: "0.6.0"]},
            {"--no-formatter", [from: "0.6.0"]},
            {"--no-js-hooks", [from: "0.6.0"]},
            {"--no-scoped-css", [from: "0.8.0"]},
            {"--tailwind", [from: "0.8.0", until: "0.9.4"]}
          ]
        }
      ]
    },
    "rails" => %{
      url: "https://guides.rubyonrails.org/",
      source: :gem,
      generators: [
        %{
          command: "rails new",
          docs_url: "https://guides.rubyonrails.org/command_line.html#rails-new",
          help: "Not all flags exist on all versions and may result in an error or be ignored.",
          default_flags: [
            "my_app",
            "--skip-keeps",
            "--skip-git",
            "--skip-bundle",
            "--skip-webpack-install"
          ],
          flags: [
            "--database=mysql",
            "--database=postgresql",
            "--database=sqlite3",
            "--skip-yarn",
            "--skip-action-mailer",
            "--skip-active-record",
            "--skip-active-storage",
            "--skip-puma",
            "--skip-action-cable",
            "--skip-sprockets",
            "--skip-spring",
            "--skip-listen",
            "--skip-coffee",
            "--skip-javascript",
            "--skip-turbolinks",
            "--skip-test",
            "--skip-system-test",
            "--skip-bootsnap",
            "--api"
          ]
        }
      ]
    },
    "webpacker" => %{
      url: "https://rubygems.org/gems/webpacker",
      source: :gem,
      generators: [
        %{
          command: "rails webpacker:install",
          docs_url: "https://github.com/rails/webpacker",
          help: "Ran on a default Rails 5.2.4 project",
          default_flags: [],
          flags: [
            "react",
            "vue",
            "angular",
            "elm",
            "stimulus"
          ]
        }
      ]
    }
  }

  def all, do: @known

  def projects(), do: all() |> Map.keys()

  def get_by(project: project) do
    all()[project]
  end

  def get_by(project: project, command: command) do
    Enum.find_value(all()[project][:generators], fn generator ->
      generator[:command] == command && generator
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

  def source_for_project(project) do
    case get_by(project: project) do
      %{source: source} -> source
      _ -> nil
    end
  end

  def flags_for_command(nil, _command), do: []

  def flags_for_command(project, command) do
    case get_by(project: project, command: command) do
      %{flags: [{_, _} | _] = flags} -> Enum.map(flags, &elem(&1, 0))
      %{flags: flags} -> flags
      _ -> []
    end
  end

  def flags_for_command(nil, _command, _version), do: []
  def flags_for_command(_project, nil, _version), do: []

  def flags_for_command(project, command, version) do
    version = if version in ["main", "master"], do: "9999.0.0", else: version

    case {version, get_by(project: project, command: command)} do
      {nil, %{flags: [{_, _} | _] = flags}} ->
        Enum.map(flags, &elem(&1, 0))

      {_version, %{flags: [{_, _} | _] = flags}} ->
        flags
        |> Enum.filter(fn
          {_flag, [from: from, until: until]} ->
            Version.compare(version, from) != :lt && Version.compare(version, until) == :lt

          {_flag, [from: from]} ->
            Version.compare(version, from) != :lt
        end)
        |> Enum.map(&elem(&1, 0))

      {_version, %{flags: flags}} ->
        flags

      _ ->
        []
    end
  end

  def help_for_command(nil, _command), do: nil

  def help_for_command(project, command) do
    case get_by(project: project, command: command) do
      %{help: help} -> help
      _ -> nil
    end
  end

  def docs_url_for_command(nil, _command), do: nil

  def docs_url_for_command(project, command) do
    case get_by(project: project, command: command) do
      %{docs_url: url} -> url
      _ -> nil
    end
  end

  def default_flags_for_command(nil, _, _), do: []
  def default_flags_for_command(_, nil, _), do: []

  def default_flags_for_command(project, command, version) do
    version = if version in ["main", "master"], do: "9999.0.0", else: version

    case {version, get_by(project: project, command: command)} do
      {nil, %{default_flags: [{_, _} | _] = default_flags}} ->
        Enum.map(default_flags, &elem(&1, 0))

      {_version, %{default_flags: [{_, _} | _] = default_flags}} ->
        default_flags
        |> Enum.filter(fn
          {_flag, [from: from, until: until]} ->
            Version.compare(version, from) != :lt && Version.compare(version, until) == :lt

          {_flag, [from: from]} ->
            Version.compare(version, from) != :lt
        end)
        |> Enum.map(&elem(&1, 0))

      {_version, %{default_flags: default_flags}} ->
        default_flags

      _ ->
        []
    end
  end

  def versions_for_project(project, command) do
    case source_for_project(project) do
      :hex -> get_hex_versions(project, command)
      :gem -> get_gem_versions(project, command)
    end
  end

  def get_hex_versions(project, command) do
    case Utility.PackageRepo.get_by(Utility.Package, name: project) do
      %{versions: versions} ->
        limit_versions(versions, project, command)

      _ ->
        []
    end
  end

  def get_gem_versions(project, _command) do
    case Utility.PackageRepo.get_by(Utility.Package, name: project) do
      %{versions: versions} -> versions
      _ -> []
    end
  end

  defp limit_versions(versions, project, command) do
    case get_by(project: project, command: command) do
      %{since: since_version} ->
        Enum.filter(
          versions,
          &(&1 in ["main", "master"] or Version.compare(&1, since_version) != :lt)
        )

      _ ->
        versions
    end
  end
end
