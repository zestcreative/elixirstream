defmodule UtilityWeb.SinkLive do
  use UtilityWeb, :live_view
  alias UtilityWeb.HTTPSink
  alias Phoenix.LiveView.JS

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "HTTP Sink")
     |> assign(:id, nil)
     |> stream(:requests, [])}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    if connected?(socket) do
      HTTPSink.unsubscribe(socket.assigns.id)
      HTTPSink.subscribe(id)
    end

    {:noreply, assign(socket, :id, id)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, push_navigate(socket, to: ~p"/sink/view/#{Ecto.UUID.generate()}")}
  end

  @impl Phoenix.LiveView
  def handle_info(payload, socket) do
    {:noreply, stream_insert(socket, :requests, payload, at: 0)}
  end

  @gif_header <<0x47, 0x49, 0x46, 0x38>>
  @png_header <<0x89, 0x50, 0x4E, 0x47>>
  @jpg_header <<0xFF, 0xD8>>
  attr :encoded, :any, default: nil
  attr :body, :any, default: nil
  attr :request, UtilityWeb.HTTPSink, required: true

  def render_body(assigns) do
    assigns =
      case assigns.request do
        %{body_params: @gif_header <> _rest = body} ->
          assign(assigns, :encoded, ["data:image/gif;base64,", Base.encode64(body)])

        %{body_params: @png_header <> _rest = body} ->
          assign(assigns, :encoded, ["data:image/png;base64,", Base.encode64(body)])

        %{body_params: @jpg_header <> _rest = body} ->
          assign(assigns, :encoded, ["data:image/jpeg;base64,", Base.encode64(body)])

        %{body_params: body, format: format} ->
          with :json <- format, {:ok, parsed} <- Jason.encode(body, pretty: true) do
            assign(assigns, :body, parsed)
          else
            _ ->
              assign(assigns, :body, inspect(body, limit: :infinity, printable_limit: :infinity))
          end
      end

    ~H"""
    <img :if={@encoded} src={@encoded} />
    <pre :if={!@encoded} class="whitespace-pre select-all"><%= @body %></pre>
    """
  end

  def hide_warning(js \\ %JS{}) do
    JS.hide(js,
      to: "#warning-box",
      transition: {"ease-in duration-300", "opacity-100", "opacity-0"}
    )
  end

  def toggle_help(js \\ %JS{}) do
    js
    |> JS.toggle(to: "#help-box")
    |> JS.remove_class("rotate-180", to: "#help-caret.rotate-180")
    |> JS.add_class("rotate-180", to: "#help-caret:not(.rotate-180)")
  end
end
