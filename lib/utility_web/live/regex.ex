defmodule UtilityWeb.RegexLive do
  @moduledoc """
  Manage the view of the user's calendar. Defaults to the month view.
  """

  use UtilityWeb, :live_view
  use Ecto.Schema
  alias Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :id, Ecto.UUID
    field :string, :string, default: ""
    field :flags, :string, default: ""
    field :regex, :string, default: ""
    field :function, :string, default: "scan"
    field :result, :any, virtual: true, default: ""
  end

  @allowed_functions ~w[scan named_captures run]

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    record = %__MODULE__{}
    {:ok,
      socket
      |> assign(:record, record)
      |> assign(:saved, false)
      |> assign_changeset(%{})
    }
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    with {:ok, regex} <- Utility.Redix.command(["HGET", id, "regex"]),
         {:ok, string} <- Utility.Redix.command(["HGET", id, "string"]),
         {:ok, function} <- Utility.Redix.command(["HGET", id, "function"]),
         {:ok, flags} <- Utility.Redix.command(["HGET", id, "flags"]) do
      record = %__MODULE__{id: id, function: function, regex: regex, string: string, flags: flags}
      {:noreply,
        socket
        |> assign(:record, record)
        |> assign(:saved, true)
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
  def handle_event("permalink", _content, socket) do
    {:ok, record} = Changeset.apply_action(socket.assigns.changeset, :insert)

    case Utility.Redix.pipeline([
      ["HSET", record.id, "string", record.string],
      ["HSET", record.id, "regex", record.regex],
      ["HSET", record.id, "function", record.function],
      ["HSET", record.id, "flags", record.flags]
    ]) do
      {:ok, _} ->
        IO.inspect record.id, label: "SAVED"
        {:noreply, push_patch(socket, to: "/regex/#{record.id}")}
      _ ->
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
    |> assign(:result, Changeset.get_field(changeset, :result))
  end

  def changeset(record, params) do
    record
    |> Changeset.cast(sort_flags(params), ~w[string flags regex function]a)
    |> Changeset.validate_inclusion(:function, @allowed_functions)
    |> Changeset.validate_format(:flags, ~r/\AU?f?i?m?s?u?x?\z/, message: "invalid flags")
    |> ensure_id()
    |> put_result()
  end

  defp sort_flags(%{"flags" => flags} = params) when is_binary(flags) do
    sorted =
      flags
      |> String.split("")
      |> Enum.sort()
      |> Enum.join("")
    Map.put(params, "flags", sorted)
  end
  defp sort_flags(params), do: params

  defp ensure_id(changeset) do
    case Changeset.get_field(changeset, :id) do
      nil -> Changeset.put_change(changeset, :id, Ecto.UUID.generate())
      _ -> changeset
    end
  end

  defp put_result(changeset) do
    result =
      case {Changeset.get_field(changeset, :function), Regex.compile(Changeset.get_field(changeset, :regex), Changeset.get_field(changeset, :flags))} do
        {"run", {:ok, regex}} ->
          Regex.run(regex, Changeset.get_field(changeset, :string))
        {"scan", {:ok, regex}} ->
          Regex.scan(regex, Changeset.get_field(changeset, :string))
        {"named_captures", {:ok, regex}} ->
          Regex.named_captures(regex, Changeset.get_field(changeset, :string))
        _ ->
          "Invalid Regex"
      end

    Changeset.put_change(changeset, :result, result)
  end
end
