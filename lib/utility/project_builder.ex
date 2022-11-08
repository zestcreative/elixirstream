defmodule Utility.ProjectBuilder do
  require Logger
  alias Utility.GenDiff.{Data, Generator}
  alias Utility.ProjectRunner

  @known_packages Utility.GenDiff.Data.projects()

  @job_opts [schedule_in: 2]
  def schedule_diff(%Generator{} = generator) do
    %{generator: generator}
    |> Utility.Workers.GenerateDiff.new(@job_opts)
    |> Oban.insert()
  end

  def default_broadcaster(_payload), do: :ok

  @timeout :timer.minutes(20)
  def diff(%Generator{} = generator, opts \\ []) do
    Logger.info("Starting a diff #{inspect(generator)}")
    %{project: project, from_version: from, to_version: to} = generator
    path_from = tmp_path("package-#{project}-#{from}-")
    path_to = tmp_path("package-#{project}-#{to}-")
    path_diff = tmp_path("diff-#{project}-#{from}-#{to}-")
    File.mkdir_p!(path_from)
    File.mkdir_p!(path_to)
    opts = Keyword.put_new(opts, :broadcaster, &default_broadcaster/1)

    try do
      with {:ok, runner_from, generated_from} <- generate_app(generator, :from, path_from, opts),
           {:ok, runner_to, generated_to} <- generate_app(generator, :to, path_to, opts),
           results <- Task.await_many([runner_from, runner_to], @timeout),
           results <- Enum.group_by(results, &elem(&1, 0), &elem(&1, 1)),
           {nil, _success} <- Map.pop(results, :error),
           {:ok, any?} <- git_diff(generated_from, generated_to, path_diff),
           {:ok, html} <- render_diff(generator, any?, generated_from, generated_to, path_diff) do
        result = Utility.Storage.put(generator, html)
        File.rm_rf(html)
        result
      else
        {errors, _good_results} ->
          {:error, errors}

        error ->
          {:error, error}
      end
    after
      File.rm_rf(path_from)
      File.rm_rf(path_to)
      File.rm_rf(path_diff)
    end
  end

  def render_diff(generator, true, from, to, path) do
    path
    |> File.stream!([:read_ahead])
    |> GitDiff.stream_patch(relative_from: from, relative_to: to)
    |> Stream.transform(
      fn -> :ok end,
      fn elem, :ok -> {[elem], :ok} end,
      fn :ok -> File.rm(path) end
    )
    |> UtilityWeb.GenDiffView.render_diff(generator)
  end

  def render_diff(generator, false, _from, _to, path) do
    File.rm(path)
    UtilityWeb.GenDiffView.render_diff(nil, generator)
  end

  def git_diff(path_from, path_to, path_out) do
    args = [
      "-c",
      "core.quotepath=false",
      "-c",
      "diff.algorithm=histogram",
      "diff",
      "--no-index",
      "--no-color",
      "--output=#{path_out}",
      path_from,
      path_to
    ]

    Logger.info("Running diff #{path_from}..#{path_to} to #{path_out}: #{inspect(args)}")

    case System.cmd("git", args) do
      {"", 1} ->
        {:ok, true}

      {"", 0} ->
        {:ok, false}

      other ->
        {:error, other}
    end
  end

  def generate_app(%{project: project, command: command} = generator, from_or_to, path, opts)
      when project in @known_packages do
    version = Map.get(generator, :"#{from_or_to}_version")
    flags = Map.get(generator, :"#{from_or_to}_flags") || []
    prefix = "#{generator.project}#{generator.id}#{from_or_to}|"

    with {:ok, runner} <- ProjectRunner.start_link([prefix: prefix] ++ opts) do
      commands =
        Enum.join(
          [
            install_archive(project, version),
            run_command(
              command,
              version,
              Data.default_flags_for_command(project, command) ++ flags
            )
          ],
          " && "
        )

      task =
        Task.async(fn ->
          ProjectRunner.run(runner, commands,
            timeout: @timeout,
            tag: docker_tag_for(command, version),
            mount: path
          )
        end)

      {:ok, task, generator_to_output_folder(command, flags, path)}
    end
  end

  def generator_to_output_folder(command, flags, path) do
    if command == "phx.new" && "--umbrella" in flags do
      Path.join([path, "my_app_umbrella"])
    else
      Path.join([path, "my_app"])
    end
  end

  @phx_new_proper Version.parse!("1.4.0-dev.0")
  @phx_new_github Version.parse!("1.3.0")
  def install_archive("phx_new", "master") do
    """
    git clone https://github.com/phoenixframework/phoenix.git &&
      (cd phoenix/installer && MIX_ENV=prod mix do deps.get, compile, archive.build, archive.install --force) &&
      rm -rf phoenix
    """
    |> String.trim()
  end

  def install_archive("phx_new", version_string) do
    version = Version.parse!(version_string)

    cond do
      Version.compare(version, @phx_new_proper) != :lt ->
        "mix archive.install --force hex phx_new #{version_string}"

      Version.compare(version, @phx_new_github) != :lt ->
        "mix archive.install --force /cache/phx_archives/phx_new-#{version_string}.ez"

      true ->
        "mix archive.install --force /cache/phx_archives/phoenix_new-#{version_string}.ez"
    end
  end

  def install_archive("phx_gen_auth", _version) do
    "mix archive.install --force hex phx_new 1.5.7"
  end

  def install_archive("rails", version) do
    "gem install rails --version #{version}"
  end

  def install_archive("webpacker", _version) do
    "gem install rails --version 5.2.4"
  end

  def install_archive(package, version) do
    "mix archive.install --force hex #{package} #{version}"
  end

  @phx_gen_auth_merged Version.parse!("1.6.0")
  def run_command("phx.gen.auth", version_string, flags) do
    with {:ok, version} <- Version.parse(version_string),
         :lt <- Version.compare(version, @phx_gen_auth_merged) do
      # This is the separate phx_gen_auth package
      """
      elixir --version &&
      #{run_command("phx.new", "1.5.7", ["my_app"])} &&
        sed -i 's/{:phoenix, "~> 1.5.7"},/{:phoenix, "~> 1.5.7"},\\n      {:phx_gen_auth, "#{version_string}", only: [:dev], runtime: false},/g' my_app/mix.exs &&
        cd my_app &&
        mix deps.get &&
        mix phx.gen.auth #{Enum.join(flags, " ")} &&
        rm -rf _build deps mix.lock
      """
    else
      _ ->
        # phx.gen.auth is merged into phx_new package
        """
        elixir --version &&
        #{run_command("phx.new", version_string, ["my_app"])} &&
          cd my_app &&
          mix deps.get &&
          mix phx.gen.auth #{Enum.join(flags, " ")} &&
          rm -rf _build deps mix.lock
        """
    end
    |> String.trim()
  end

  def run_command("phx.new", "master", flags), do: run_command("phx.new", "999.0.0", flags)

  def run_command("phx.new", :standard, [where | _] = flags) do
    """
    elixir --version &&
    yes n | mix phx.new #{Enum.join(flags, " ")} &&
      (sed -i 's/secret_key_base: ".*"/secret_key_base: "foo"/g' #{where}/**/*.ex* &> /dev/null || true) &&
      (sed -i 's/signing_salt: ".*"/signing_salt: "foo"/g' #{where}/**/*.ex* &> /dev/null || true)
    """
  end

  def run_command("phx.new", :umbrella, [where | _] = flags) do
    """
    elixir --version &&
    yes n | mix phx.new #{Enum.join(flags, " ")} &&
      (sed -i 's/secret_key_base: ".*"/secret_key_base: "foo"/g' #{where}_umbrella/**/*.ex* &> /dev/null || true) &&
      (sed -i 's/signing_salt: ".*"/signing_salt: "foo"/g' #{where}_umbrella/**/*.ex* &> /dev/null || true)
    """
  end

  def run_command("phx.new", version_string, [where | _] = flags) do
    version = Version.parse!(version_string)

    case {Version.compare(version, @phx_new_github), "--umbrella" in flags} do
      {:lt, _} ->
        """
        elixir --version &&
        yes n | mix phoenix.new #{Enum.join(flags, " ")} &&
          sed -i 's/secret_key_base: ".*"/secret_key_base: "foo"/g' #{where}/**/*.ex* &&
          sed -i 's/signing_salt: ".*"/signing_salt: "foo"/g' #{where}/**/*.ex*
        """

      {_, false} ->
        run_command("phx.new", :standard, flags)

      {_, true} ->
        run_command("phx.new", :umbrella, flags)
    end
    |> String.trim()
  end

  def run_command("rails new", _version_string, [where | _] = flags) do
    """
    ruby --version && gem --version &&
    rails new #{Enum.join(flags, " ")} &&
      cd #{where} &&
      (rm -f config/credentials.yml.enc &> /dev/null || true) &&
      (rm -f config/master.key &> /dev/null || true)
    """
    |> String.trim()
  end

  def run_command("rails webpacker:install", version_string, [:none]) do
    """
    ruby --version && gem --version &&
    #{run_command("rails new", "5.2.4", ["my_app", "--skip-keeps", "--skip-git", "--skip-bundle", "--skip-webpack-install"])} &&
      echo "gem 'webpacker', '#{version_string}'" >> Gemfile &&
      bundle --quiet &&
      bundle exec rails webpacker:install
    """
    |> String.trim()
  end

  def run_command("rails webpacker:install", version_string, [framework]) do
    """
    ruby --version && gem --version &&
    #{run_command("rails webpacker:install", version_string, [:none])} &&
      bundle exec rails webpacker:install:#{framework} &&
      rm -rf node_modules tmp yarn.lock
    """
    |> String.trim()
  end

  def run_command("rails webpacker:install", version_string, []) do
    """
    ruby --version && gem --version &&
    #{run_command("rails webpacker:install", version_string, [:none])} &&
      rm -rf node_modules tmp yarn.lock
    """
    |> String.trim()
  end

  def run_command("rails webpacker:install", _version_string, _) do
    "echo 'Cannot select multiple frameworks' && exit 1"
  end

  def run_command("nerves.new", _version_string, [where | _] = flags) do
    """
    elixir --version &&
    mix nerves.new #{Enum.join(flags, " ")} &&
      (sed -i 's/-setcookie.*/-setcookie foo/g' #{where}/rel/vm.args &> /dev/null || true)
    """
    |> String.trim()
  end

  def run_command(command, _version_string, flags) do
    """
    elixir --version &&
    mix #{command} #{Enum.join(flags, " ")}
    """
  end

  @phx_latest_at Version.parse!("1.7.0-rc.0")
  @phx_112_at Version.parse!("1.6.0")
  @phx_111_at Version.parse!("1.3.0")
  def docker_tag_for("phx.new", "master"), do: "latest"

  def docker_tag_for("phx.new", version) do
    version = Version.parse!(version)

    cond do
      Version.compare(version, @phx_latest_at) != :lt -> "latest"
      Version.compare(version, @phx_112_at) != :lt -> "112"
      Version.compare(version, @phx_111_at) != :lt -> "111"
      true -> "old"
    end
  end

  def docker_tag_for("rails new", _version), do: "rails"
  def docker_tag_for("rails webpacker:install", _version), do: "rails"
  def docker_tag_for(_command, _version), do: "latest"

  defp tmp_path(prefix) do
    Path.join([
      Application.get_env(:utility, :storage_dir),
      "builder",
      prefix <> Base.encode16(:crypto.strong_rand_bytes(4))
    ])
  end
end
