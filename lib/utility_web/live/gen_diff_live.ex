defmodule UtilityWeb.GenDiffLive do
  @moduledoc """
  Perform git diffing for generators' output and store the result HTML into a cache.
  """

  use UtilityWeb, :live_view
  alias Utility.ProjectBuilder
  alias Utility.GenDiff.Data
  alias Utility.GenDiff.Storage
  alias Utility.GenDiff.Generator
  alias Ecto.Changeset

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    record = %Generator{}

    {:ok,
     socket
     |> assign(page_title: "Generator Diff")
     |> assign(record: record, building: false, finished_building: false)
     |> assign(form: record |> Generator.changeset(%{}) |> to_form())
     |> assign_changeset(%{})
     |> stream_configure(:lines_0, dom_id: fn {_safe_iodata, id} -> "lines-0-#{id}" end)
     |> stream_configure(:lines_1, dom_id: fn {_safe_iodata, id} -> "lines-1-#{id}" end)
     |> stream_configure(:lines_2, dom_id: fn {_safe_iodata, id} -> "lines-2-#{id}" end)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"generator" => params}, socket) do
    {:noreply, assign_changeset(socket, params)}
  end

  def handle_event("validate", _params, socket), do: {:noreply, socket}

  @theme AnsiToHTML.Theme.new(%{container: {:pre, [class: "runner-line"]}})
  @runners Keyword.get(Application.compile_env!(:utility, Oban)[:queues] || [], :builder, 0)
  @waiting AnsiToHTML.generate_phoenix_html(
             """
             I haven't seen this combination of versions and flags before! No worries, I'll generate
             the diff right now. The result will be stored. I'm limited to #{@runners} runner(s) to
             help keep the site responsive. Waiting in line now for runner. Just sit tight.

             Once started, you'll be able to see the progress of the project being built. The left
             side will contain progress of building the FROM combination, and the right side will
             contain progress of building the TO combination. Diffs against master will only be stored
             up to 12 hours.

             If you navigate away, the diff will still be built but you won't be able to monitor
             progress.
             """,
             @theme
           )
  @impl Phoenix.LiveView
  def handle_event("diff", %{"generator" => params}, socket) do
    with {:ok, generator} <- Generator.apply(params),
         {{:error, :not_found}, _} <- {Storage.get(generator), generator},
         {:ok, _} <- ProjectBuilder.schedule_diff(generator) do
      topic = "hexgen:progress:#{generator.project}:#{generator.id}"
      UtilityWeb.Endpoint.subscribe(topic)

      {:noreply,
       socket
       |> assign(generator: generator, finished_building: false, building: true)
       |> stream(:lines_0, [], reset: true)
       |> stream(:lines_1, [], reset: true)
       |> stream(:lines_2, [], reset: true)
       |> stream_insert(:lines_0, {@waiting, "waiting"})
       |> runner_to_id(generator, :from)
       |> runner_to_id(generator, :to)
       |> push_event("scroll", %{to: "#runners"})}
    else
      {{:ok, _diff_stream}, generator} ->
        {:noreply, redirect(socket, to: show_path_for(generator))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("diff", _params, socket) do
    {:noreply, put_flash(socket, :error, "You know... like... fill out stuff")}
  end

  @impl Phoenix.LiveView
  def handle_info({:progress, _, "all-finished"}, socket) do
    {:noreply,
     socket
     |> assign(:finished_building, true)
     |> redirect(to: show_path_for(socket.assigns.generator))}
  end

  @impl Phoenix.LiveView
  def handle_info({:progress, _, "all-finished-error"}, socket) do
    {:noreply,
     socket
     |> assign(:finished_building, true)
     |> put_flash(:error, "there was an error while building")}
  end

  def handle_info({:progress, line, id}, socket) do
    line = AnsiToHTML.generate_phoenix_html(line, @theme)

    cond do
      String.starts_with?(id, socket.assigns.runner_from) ->
        {:noreply, stream_insert(socket, :lines_1, {line, id})}

      String.starts_with?(id, socket.assigns.runner_to) ->
        {:noreply, stream_insert(socket, :lines_2, {line, id})}

      true ->
        {:noreply, stream_insert(socket, :lines_0, {line, id})}
    end
  end

  defp runner_to_id(socket, generator, from_or_to) do
    assign(socket, :"runner_#{from_or_to}", "#{generator.project}#{generator.id}#{from_or_to}")
  end

  defp show_path_for(generator) do
    ~p"/gendiff/#{generator.project}/#{generator.id}"
  end

  defp assign_changeset(socket, params) do
    {params, record} = maybe_reset(params, socket.assigns.form, socket.assigns.record)
    changeset = Generator.changeset(record, params)

    project = Changeset.get_field(changeset, :project)

    changeset =
      case Data.commands_for_project(project) do
        [command] -> Changeset.put_change(changeset, :command, command)
        _ -> changeset
      end

    from = Changeset.get_field(changeset, :from_version)
    to = Changeset.get_field(changeset, :to_version)
    command = Changeset.get_field(changeset, :command)

    socket
    |> assign(:form, to_form(changeset))
    |> assign(:project, project)
    |> assign(:project_url, Changeset.get_field(changeset, :url))
    |> assign(:project_source, Changeset.get_field(changeset, :source))
    |> assign(:command, command)
    |> assign(:command_help, Changeset.get_field(changeset, :help))
    |> assign(:docs_url, Changeset.get_field(changeset, :docs_url))
    |> assign(:from_version, from)
    |> assign(:to_version, to)
    |> assign(:from_versions, versions_for(project, command, ceiling: to))
    |> assign(:to_versions, versions_for(project, command, floor: from))
    |> assign(:from_flags, Changeset.get_field(changeset, :from_flags, []))
    |> assign(:to_flags, Changeset.get_field(changeset, :to_flags, []))
    |> assign(:available_from_flags, Data.flags_for_command(project, command, from))
    |> assign(:available_to_flags, Data.flags_for_command(project, command, to))
  end

  defp maybe_reset(%{"project" => project} = params, %{params: %{"project" => project}}, record) do
    {params, record}
  end

  defp maybe_reset(
         %{"project" => different_project} = params,
         %{params: %{"project" => project}},
         _record
       )
       when different_project != project do
    {
      Map.merge(params, %{"from_version" => nil, "to_version" => nil, "command" => nil}),
      %Generator{}
    }
  end

  defp maybe_reset(params, _changeset, record), do: {params, record}

  defp versions_for(nil, _command, _opts), do: []
  defp versions_for(_project, nil, _opts), do: []

  defp versions_for(project, command, opts) do
    {compare, limit} = if floor = opts[:floor], do: {:lt, floor}, else: {nil, nil}
    {compare, limit} = if ceil = opts[:ceiling], do: {:gt, ceil}, else: {compare, limit}

    limit =
      if limit do
        case Version.parse(limit) do
          {:ok, version} -> version
          :error -> limit
        end
      end

    case {limit, compare, Data.versions_for_project(project, command)} do
      {_, _, []} ->
        []

      {nil, nil, versions} ->
        versions

      {main, :gt, versions} when main in ["master", "main"] ->
        versions

      {main, :lt, _versions} when main in ["master", "main"] ->
        [main]

      {limit, compare, versions} ->
        Enum.reject(versions, fn version ->
          case Version.parse(version) do
            {:ok, version} -> Version.compare(version, limit) == compare
            :error -> false
          end
        end)
    end
  end

  @package_placeholder [[key: "Select project...", selected: true, value: "", disabled: true]]
  defp generator_package_options() do
    projects = Data.projects() |> Enum.map(&[key: &1, value: &1])
    @package_placeholder ++ projects
  end

  @generator_placeholder [[key: "Select generator...", selected: true, value: "", disabled: true]]
  defp generator_options(nil), do: @generator_placeholder

  defp generator_options(project) do
    project
    |> Data.commands_for_project()
    |> Enum.map(&[key: &1, value: &1])
    |> case do
      [generator] ->
        @generator_placeholder ++ [Keyword.put(generator, :selected, true)]

      generators ->
        @generator_placeholder ++ generators
    end
  end

  @version_placeholder [[key: "Select version...", selected: true, value: "", disabled: true]]
  defp version_options([version]), do: [[key: version, value: version, selected: true]]

  defp version_options(versions) do
    versions = Enum.map(versions, &[key: &1, value: &1])
    @version_placeholder ++ versions
  end
end
