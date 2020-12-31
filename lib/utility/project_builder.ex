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

  @timeout :timer.minutes(10)
  def diff(%Generator{} = generator, opts \\ []) do
    Logger.debug("Starting a diff #{inspect(generator)}")
    %{project: project, from_version: from, to_version: to} = generator
    path_from = tmp_path("package-#{project}-#{from}-")
    path_to = tmp_path("package-#{project}-#{to}-")
    File.mkdir_p!(path_from)
    File.mkdir_p!(path_to)
    opts = Keyword.put_new(opts, :broadcaster, &default_broadcaster/1)

    try do
      path_diff = tmp_path("diff-#{project}-#{from}-#{to}-")

      with {:ok, runner_from, generated_from} <- generate_app(generator, :from, path_from, opts),
           {:ok, runner_to, generated_to} <- generate_app(generator, :to, path_to, opts),
           results <- Task.await_many([runner_from, runner_to], @timeout),
           results <- Enum.group_by(results, &elem(&1, 0), &elem(&1, 1)),
           {nil, _success} <- Map.pop(results, :error),
           {:ok, any?} <- git_diff(generated_from, generated_to, path_diff),
           {:ok, html} <- render_diff(generator, any?, generated_from, generated_to, path_diff) do
        Utility.Storage.put(generator, html)
      else
        {errors, _good_results} ->
          {:error, errors}
        error ->
          error
      end
    after
      File.rm_rf(path_from)
      File.rm_rf(path_to)
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
    case System.cmd("git", [
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
    ]) do
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
        Enum.join([
          install_archive(project, version),
          run_command(command, version, Data.default_flags_for_command(command) ++ flags)
        ], " && ")

      task =
        Task.async(fn ->
          ProjectRunner.run(runner, commands, timeout: @timeout, tag: tag_for(command, version), mount: path)
        end)

      {:ok, task, Path.join([path, "my_app"])}
    end
  end

  @phx_new_proper Version.parse!("1.4.0-dev.0")
  @phx_new_github Version.parse!("1.3.0")
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

  def install_archive(package, version) do
    "mix archive.install --force hex #{package} #{version}"
  end

  def run_command("phx.gen.auth", version_string, flags) do
    """
    #{run_command("phx.new", "1.5.7", ["my_app"])} &&
      sed -i 's/{:phoenix, "~> 1.5.7"},/{:phoenix, "~> 1.5.7"},\\n      {:phx_gen_auth, "#{version_string}", only: [:dev], runtime: false},/g' my_app/mix.exs &&
      cd my_app &&
      mix deps.get &&
      mix phx.gen.auth #{Enum.join(flags, " ")} &&
      rm -rf _build deps mix.lock
    """ |> String.trim()
  end

  def run_command("phx.new", version_string, [where | _] = flags) do
    version = Version.parse!(version_string)
    case {Version.compare(version, @phx_new_github), "--umbrella" in flags} do
      {:lt, _} ->
        """
        yes n | mix phoenix.new #{Enum.join(flags, " ")} &&
          sed -i 's/secret_key_base: ".*"/secret_key_base: "foo"/g' #{where}/config/prod.secret.exs &&
          sed -i 's/secret_key_base: ".*"/secret_key_base: "foo"/g' #{where}/config/config.exs &&
          sed -i 's/signing_salt: ".*"/signing_salt: "foo"/g' #{where}/config/config.exs &&
          sed -i 's/signing_salt: ".*"/signing_salt: "foo"/g' #{where}/lib/#{where}/endpoint.ex
        """ |> String.trim()
      {_, false} ->
        """
        yes n | mix phx.new #{Enum.join(flags, " ")} &&
          sed -i 's/secret_key_base: ".*"/secret_key_base: "foo"/g' #{where}/config/prod.secret.exs &&
          sed -i 's/secret_key_base: ".*"/secret_key_base: "foo"/g' #{where}/config/config.exs &&
          sed -i 's/signing_salt: ".*"/signing_salt: "foo"/g' #{where}/config/config.exs &&
          sed -i 's/signing_salt: ".*"/signing_salt: "foo"/g' #{where}/lib/#{where}_web/endpoint.ex
        """ |> String.trim()
      {_, true} ->
        """
        yes n | mix phx.new #{Enum.join(flags, " ")} &&
          (sed -i 's/secret_key_base: ".*"/secret_key_base: "foo"/g' #{where}_umbrella/config/prod.secret.exs &> /dev/null || true) &&
          (sed -i 's/secret_key_base: ".*"/secret_key_base: "foo"/g' #{where}_umbrella/config/config.exs &> /dev/null || true) &&
          (sed -i 's/signing_salt: ".*"/signing_salt: "foo"/g' #{where}_umbrella/config/config.exs &> /dev/null || true) &&
          (sed -i 's/secret_key_base: ".*"/secret_key_base: "foo"/g' #{where}_umbrella/apps/#{where}_web/config/prod.secret.exs &> /dev/null || true) &&
          (sed -i 's/secret_key_base: ".*"/secret_key_base: "foo"/g' #{where}_umbrella/apps/#{where}_web/config/config.exs &> /dev/null || true) &&
          (sed -i 's/signing_salt: ".*"/signing_salt: "foo"/g' #{where}_umbrella/apps/#{where}_web/config/config.exs &> /dev/null || true) &&
          sed -i 's/signing_salt: ".*"/signing_salt: "foo"/g' #{where}_umbrella/apps/#{where}_web/lib/#{where}_web/endpoint.ex
        """ |> String.trim()
    end
  end

  def run_command("nerves.new", _version_string, [where | _] = flags) do
    """
    mix nerves.new #{Enum.join(flags, " ")} &&
      (sed -i 's/-setcookie.*/-setcookie foo/g' #{where}/rel/vm.args &> /dev/null || true)
    """ |> String.trim()
  end

  def run_command(command, _version_string, flags), do: "mix #{command} #{Enum.join(flags, " ")}"

  @phx_latest_at Version.parse!("1.3.0")
  def tag_for("phx.new", version) do
    version = Version.parse!(version)
    if Version.compare(version, @phx_latest_at) == :lt, do: "old", else: "latest"
  end
  def tag_for(_command, _version), do: "latest"

  defp tmp_path(prefix) do
    random_string = Base.encode16(:crypto.strong_rand_bytes(4))
    Path.join([System.tmp_dir!(), "utility", prefix <> random_string])
  end
end
