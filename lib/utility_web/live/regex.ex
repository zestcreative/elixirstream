defmodule UtilityWeb.RegexLive do
  @moduledoc """
  Perform regex on a given string, and visualize the matches back to the user
  """

  use UtilityWeb, :live_view
  use Ecto.Schema
  alias Ecto.Changeset
  alias Utility.Cache
  require Logger

  @primary_key false
  embedded_schema do
    field(:id, Ecto.UUID)
    field(:string, :string, default: "")
    field(:flags, :string, default: "")
    field(:regex, :string, default: "")
    field(:function, :string, default: "scan")
    field(:result, :any, virtual: true, default: "")
    field(:matched, :any, virtual: true, default: [])
    field(:help_tab, :string, default: "cheatsheet")
    field(:pasta, :string, virtual: true, default: "")
  end

  @allowed_functions ~w[scan named_captures run]
  @allowed_tabs ~w[cheatseet flags recipes]

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    record = %__MODULE__{}

    {:ok,
     socket
     |> assign(:record, record)
     |> assign(:page_title, "Regex Tester")
     |> assign_changeset(%{})}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    with {:ok, regex} <- Cache.hash_get(cache_key_for(id), "regex"),
         {:ok, string} <- Cache.hash_get(cache_key_for(id), "string"),
         {:ok, function} <- Cache.hash_get(cache_key_for(id), "function"),
         {:ok, flags} <- Cache.hash_get(cache_key_for(id), "flags") do
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
  def handle_event("validate", _params, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("help-tab", %{"tab" => tab}, socket) do
    {:noreply,
     assign_changeset(socket, Map.merge(socket.assigns.changeset.params, %{"help_tab" => tab}))}
  end

  @one_year 60 * 60 * 24 * 365
  @impl Phoenix.LiveView
  def handle_event("permalink", _content, socket) do
    with {:ok, record} <- Changeset.apply_action(socket.assigns.changeset, :insert),
         record <- %{record | id: Ecto.UUID.generate()},
         {:ok, _} <-
           Cache.multi([
             [:hash_set, cache_key_for(record.id), "string", record.string],
             [:hash_set, cache_key_for(record.id), "regex", record.regex],
             [:hash_set, cache_key_for(record.id), "function", record.function],
             [:hash_set, cache_key_for(record.id), "flags", record.flags],
             [:expire, cache_key_for(record.id), @one_year]
           ]) do
      {:noreply,
       socket
       |> put_flash(:info, "Saved regex for 1 year. See browser URL")
       |> push_patch(to: "/regex/#{record.id}")}
    else
      {:error, %Changeset{}} ->
        {:noreply, put_flash(socket, :error, "You may only save a valid regex")}

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

  @two_mb 2_000_000
  def changeset(record, params) do
    start = System.monotonic_time()

    changeset =
      record
      |> Changeset.cast(params, ~w[help_tab string flags regex function]a)
      |> Changeset.validate_length(:regex, max: 6500, message: "must be under 6,500 characters")
      |> Changeset.validate_length(:string, max: @two_mb, message: "must be under 2MB")
      |> Changeset.validate_inclusion(:function, @allowed_functions)
      |> Changeset.validate_inclusion(:help_tab, @allowed_tabs)
      |> put_result()
      |> put_pasta()

    :telemetry.execute(
      [:utility, :regex, :render],
      %{duration: System.monotonic_time() - start},
      %{}
    )

    changeset
  end

  defp put_pasta(%{valid?: true} = changeset) do
    fun = Changeset.get_field(changeset, :function)
    regex = Changeset.get_field(changeset, :regex)
    flags = Changeset.get_field(changeset, :flags)
    pasta = "Regex.#{fun}(~r/#{regex}/#{flags}, value)"
    Changeset.put_change(changeset, :pasta, pasta)
  end

  defp put_pasta(changeset), do: changeset

  defp put_result(%{valid?: true} = changeset) do
    string = Changeset.get_field(changeset, :string)

    :telemetry.execute(
      [:utility, :regex, :payload],
      %{payload: byte_size(string)},
      %{}
    )

    {result, indexes, changeset} =
      do_result(
        Changeset.get_field(changeset, :function),
        Regex.compile(
          Changeset.get_field(changeset, :regex),
          Changeset.get_field(changeset, :flags)
        ),
        string,
        changeset
      )

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

  defp do_result("run", {:ok, regex}, string, changeset) do
    {
      Regex.run(regex, string),
      Regex.run(regex, string, return: :index),
      changeset
    }
  end

  defp do_result("scan", {:ok, regex}, string, changeset) do
    {
      Regex.scan(regex, string),
      Regex.scan(regex, string, return: :index),
      changeset
    }
  end

  defp do_result("named_captures", {:ok, regex}, string, changeset) do
    {
      Regex.named_captures(regex, string),
      Regex.named_captures(regex, string, return: :index),
      changeset
    }
  end

  defp do_result(_, {:error, {error, pos}}, _string, changeset) do
    {
      "#{error} (at character #{pos})",
      [],
      Changeset.add_error(changeset, :regex, "is invalid")
    }
  end

  defp get_parts(nil, _string), do: []
  defp get_parts(%{} = indexes, string), do: indexes |> Map.values() |> get_parts(string)

  defp get_parts(indexes, string) when is_list(indexes) do
    indexes
    |> List.flatten()
    |> Enum.sort_by(fn {start, length} -> {start, -(start + length)} end)
    |> Enum.reduce({string, 0, []}, &to_matches/2)
    |> ensure_last_part(byte_size(string))
  end

  # subpatterns that were not assigned a value in the match are returned as the tuple {-1,0}
  # ignoring for now
  defp to_matches({-1, 0}, {string, last_pos, acc}) do
    {string, last_pos, acc}
  end

  # These are matches that have already been processed. Eg, Sub-group matches included in the
  # bigger group.
  defp to_matches({start, length}, {string, last_pos, acc}) when start + length <= last_pos do
    {string, last_pos, acc}
  end

  # the first match at the beginning of the string
  defp to_matches({0 = start, len}, {string, 0 = start, acc}) do
    {string, start + len, [{:matched, start, binary_part(string, start, len)} | acc]}
  end

  # the first match in the middle of the string
  defp to_matches({start, len}, {string, 0, acc}) do
    {string, start + len,
     [
       {:unmatched, 0, binary_part(string, 0, start)},
       {:matched, start, binary_part(string, start, len)}
       | acc
     ]}
  end

  # a match with a gap from the last match
  defp to_matches({start, len}, {string, last, acc}) when start + len > last do
    {string, start + len,
     [
       {:unmatched, last, binary_part(string, last, start - last)},
       {:matched, start, binary_part(string, start, len)}
       | acc
     ]}
  end

  # rest
  defp to_matches({start, len}, {string, _last, acc}) do
    {string, start + len, [{:matched, start, binary_part(string, start, len)} | acc]}
  end

  defp ensure_last_part({_string, _last_pos, parts}, 0), do: parts
  defp ensure_last_part({string, 0, []}, _total_size), do: [{:unmatched, 0, string}]
  defp ensure_last_part({_string, 0, parts}, _string_size), do: parts
  defp ensure_last_part({_string, string_size, parts}, string_size), do: parts

  defp ensure_last_part({string, last_pos, parts}, string_last) when last_pos < string_last do
    [[{:unmatched, last_pos, binary_part(string, last_pos, string_last - last_pos)}] | parts]
  end

  defp ensure_last_part({_string, _last_pos, parts}, _string_last), do: parts

  defp cache_key_for(id), do: "regex-#{id}"
end
