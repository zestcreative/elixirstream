defmodule Utility.GenDiff.Data do
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
            "--binary-id",
            "--database=mssql",
            "--database=mysql",
            "--database=postgres",
            "--database=sqlite3",
            "--live",
            "--no-dashboard",
            "--no-ecto",
            "--no-gettext",
            "--no-html",
            "--no-mailer",
            "--no-webpack",
            "--no-assets",
            "--umbrella"
          ]
        },
        %{
          command: "phx.gen.auth",
          docs_url: "https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Auth.html",
          default_flags: ["Accounts", "User", "users"],
          help:
            "phx.gen.auth used to be distributed separately as phx_gen_auth, but was merged into Phoenix in 1.6",
          flags: [
            "--binary-id",
            "--no-binary-id",
            "--hashing-lib=bcrypt",
            "--hashing-lib=pbkdf2",
            "--hashing-lib=argon2"
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
            "--binary-id",
            "--no-binary-id"
          ]
        }
      ]
    },
    "nerves_bootstrap" => %{
      url: "https://hex.pm/packages/nerves_bootstrap",
      source: :hex,
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
      %{flags: flags} -> flags
      _ -> []
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

  def default_flags_for_command(nil, _), do: []

  def default_flags_for_command(project, command) do
    case get_by(project: project, command: command) do
      %{default_flags: default_flags} -> default_flags
      _ -> []
    end
  end

  def versions_for_project(project) do
    case source_for_project(project) do
      :hex -> get_hex_versions(project)
      :gem -> get_gem_versions(project)
    end
  end

  def get_hex_versions(project) do
    case Utility.PackageRepo.get_by(Utility.Package, name: project) do
      %{versions: versions} -> versions
      _ -> []
    end
  end

  def get_gem_versions(project) do
    case Utility.PackageRepo.get_by(Utility.Package, name: project) do
      %{versions: versions} -> versions
      _ -> []
    end
  end
end
