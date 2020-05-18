defmodule UtilityWeb.RegexLive do
  @moduledoc """
  Manage the view of the user's calendar. Defaults to the month view.
  """

  use UtilityWeb, :live_view
  use Ecto.Schema
  alias Ecto.Changeset
  require Logger

  @primary_key false
  embedded_schema do
    field :id, Ecto.UUID
    field :string, :string, default: ""
    field :flags, :string, default: ""
    field :regex, :string, default: ""
    field :function, :string, default: "scan"
    field :result, :any, virtual: true, default: ""
    field :matched, :any, virtual: true, default: []
    field :help_tab, :string, default: "cheatsheet"
    field :pasta, :string, virtual: true, default: ""
  end

  @allowed_functions ~w[scan named_captures run]
  @allowed_tabs ~w[cheatseet flags]

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    record = %__MODULE__{}
    {:ok,
      socket
      |> assign(:record, record)
      |> assign(:page_title, "Regex Tester")
      |> assign(:tooltip, %{})
      |> assign_changeset(%{})
    }
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    with {:ok, regex} <- Utility.Redix.command(["HGET", cache_key_for(id), "regex"]),
         {:ok, string} <- Utility.Redix.command(["HGET", cache_key_for(id), "string"]),
         {:ok, function} <- Utility.Redix.command(["HGET", cache_key_for(id), "function"]),
         {:ok, flags} <- Utility.Redix.command(["HGET", cache_key_for(id), "flags"]) do
      record = %__MODULE__{id: id, function: function, regex: regex, string: string, flags: flags}
      {:noreply,
        socket
        |> assign(:record, record)
        |> assign_changeset(%{})}
    else
      _ -> {:noreply, put_flash(socket, :error, "Could not find saved regex")}
    end
  end
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("validate", %{"regex_live" => params}, socket) do
    {:noreply, assign_changeset(socket, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("help-tab", %{"tab" => tab}, socket) do
    {:noreply, assign_changeset(socket, Map.merge(socket.assigns.changeset.params, %{"help_tab" => tab}))}
  end

  @impl Phoenix.LiveView
  @tooltips %{
    "U" => :ungreedy,
    "f" => :firstline,
    "i" => :caseless,
    "m" => :multiline,
    "s" => :dotall,
    "u" => :unicode,
    "x" => :extended,
  }

  def handle_event("toggle-tooltip", %{"tooltip" => which_raw}, socket) do
    case Map.get(@tooltips, which_raw) do
      nil ->
        {:noreply, socket}
      which ->
        tooltip = Map.update(socket.assigns.tooltip, which, true, fn x -> !x end)
        {:noreply, assign(socket, :tooltip, tooltip)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("clear", _content, socket) do
    {:noreply,
      socket
      |> assign(:record, %__MODULE__{})
      |> assign_changeset(%{})
    }
  end

  @one_year 60 * 60 * 24 * 365
  @impl Phoenix.LiveView
  def handle_event("permalink", _content, socket) do
    {:ok, record} = Changeset.apply_action(socket.assigns.changeset, :insert)
    record = %{record | id: Ecto.UUID.generate()}

    case Utility.Redix.pipeline([
      ["HSET", cache_key_for(record.id), "string", record.string],
      ["HSET", cache_key_for(record.id), "regex", record.regex],
      ["HSET", cache_key_for(record.id), "function", record.function],
      ["HSET", cache_key_for(record.id), "flags", record.flags],
      ["EXPIRE", cache_key_for(record.id), @one_year]
    ]) do
      {:ok, _} ->
        {:noreply,
          socket
          |> push_patch(to: "/regex/#{record.id}")}
      error ->
        Logger.error(inspect(error))
        {:noreply, put_flash(socket, :error, "Could not save regex")}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    UtilityWeb.RegexView.render("show.html", assigns)
  end

  defp assign_changeset(socket, params) do
    changeset = changeset(socket.assigns.record, params)
    socket
    |> assign(:changeset, Map.put(changeset, :action, :insert))
    |> assign(:help_tab, Changeset.get_field(changeset, :help_tab))
    |> assign(:function, Changeset.get_field(changeset, :function))
    |> assign(:matched, Changeset.get_field(changeset, :matched))
    |> assign(:pasta, Changeset.get_field(changeset, :pasta))
    |> assign(:result, Changeset.get_field(changeset, :result))
  end

  @two_mb 1_024 * 10 * 2
  def changeset(record, params) do
    record
    |> Changeset.cast(params, ~w[help_tab string flags regex function]a)
    |> Changeset.validate_length(:regex, max: 6500, message: "must be under 6,500 characters")
    |> Changeset.validate_length(:string, max: @two_mb, message: "must be under 2MB")
    |> Changeset.validate_inclusion(:function, @allowed_functions)
    |> Changeset.validate_inclusion(:help_tab, @allowed_tabs)
    |> put_result()
    |> put_pasta()
  end

  defp put_result(%{valid?: true} = changeset) do
    string = Changeset.get_field(changeset, :string)
    {result, indexes} =
      case {Changeset.get_field(changeset, :function), Regex.compile(Changeset.get_field(changeset, :regex), Changeset.get_field(changeset, :flags))} do
        {"run", {:ok, regex}} ->
          {
            Regex.run(regex, string),
            Regex.run(regex, string, return: :index)
          }
        {"scan", {:ok, regex}} ->
          {
            Regex.scan(regex, string),
            Regex.scan(regex, string, return: :index)
          }
        {"named_captures", {:ok, regex}} ->
          {
            Regex.named_captures(regex, string),
            Regex.named_captures(regex, string, return: :index)
          }
        {_, {:error, {error, pos}}} ->
          {"#{error} (at character #{pos})", []}
      end


    parts =
      indexes
      |> get_parts(string)
      |> List.flatten()
      |> Enum.sort_by(fn {_, x, _} -> x end)
      |> Enum.map(fn {result, _, string} -> {result, string} end)


    changeset
    |> Changeset.put_change(:result, result)
    |> Changeset.put_change(:matched, parts)
  end
  defp put_result(changeset), do: changeset

  defp get_parts(nil, _string), do: []
  defp get_parts(%{} = indexes, string), do: indexes |> Map.values() |> get_parts(string)
  defp get_parts(indexes, string) when is_list(indexes) do
    indexes
    |> List.flatten()
    |> Enum.reduce({nil, []}, fn match, acc ->
      case {match, acc} do
        {{0, len}, {nil, []}} ->
          {len, [{:matched, 0, binary_part(string, 0, len)}]}
        {{start, len}, {nil, []}} ->
          {start + len, [
            {:unmatched, 0, binary_part(string, 0, start)},
            {:matched, start, binary_part(string, start, len)},
          ]}
        {{start, len}, {last, acc}} when start + len != last ->
          {start + len, [[
            {:matched, start, binary_part(string, start, len)},
            {:unmatched, last, binary_part(string, last, start - last)}
          ] | acc]}
        {{start, len}, {_last, acc}} ->
          {start + len, [[{:matched, start, binary_part(string, start, len)}] | acc]}
      end
    end)
    |> ensure_last_part(String.length(string), string)
  end

  defp ensure_last_part({_last, parts}, nil, _string), do: parts
  defp ensure_last_part({nil, nil}, _last, string), do: [{:unmatched, 0, string}]
  defp ensure_last_part({nil, []}, _last, string), do: [{:unmatched, 0, string}]
  defp ensure_last_part({nil, parts}, _last, _string), do: parts
  defp ensure_last_part({last, parts}, last, _string), do: parts
  defp ensure_last_part({last, parts}, string_last, string) when last < string_last do
    [[{:unmatched, last, binary_part(string, last, string_last - last)}] | parts]
  end
  defp ensure_last_part({_last, parts}, _string_last, _string), do: parts

  defp put_pasta(%{valid?: true} = changeset) do
    fun = Changeset.get_field(changeset, :function)
    regex = Changeset.get_field(changeset, :regex)
    flags = Changeset.get_field(changeset, :flags)
    pasta = "Regex.#{fun}(~r/#{regex}/#{flags}, value)"
    Changeset.put_change(changeset, :pasta, pasta)
  end
  defp put_pasta(changeset), do: changeset

  defp cache_key_for(id), do: "regex-#{id}"
end
