defmodule UtilityWeb.SinkLive do
  use UtilityWeb, :live_view
  alias UtilityWeb.HttpSink
  alias Phoenix.LiveView.JS

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "HTTP Sink")
     |> assign(:id, nil)
     |> assign(:requests, []), temporary_assigns: [requests: []]}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    if connected?(socket) do
      HttpSink.unsubscribe(socket.assigns.id)
      HttpSink.subscribe(id)
    end

    {:noreply, assign(socket, :id, id)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, push_redirect(socket, to: Routes.sink_path(socket, :show, Ecto.UUID.generate()))}
  end

  @impl Phoenix.LiveView
  def handle_info(payload, socket) do
    {:noreply, assign(socket, requests: [payload])}
  end

  @gif_header <<0x47, 0x49, 0x46, 0x38>>
  @png_header <<0x89, 0x50, 0x4E, 0x47>>
  @jpg_header <<0xFF, 0xD8>>
  defp render_body(%{format: :json, body_params: body}) do
    case Jason.encode(body, pretty: true) do
      {:ok, parsed} ->
        Phoenix.HTML.Tag.content_tag(:pre, parsed, class: "whitespace-pre select-all")

      {:error, _} ->
        render_body(%{body_params: body})
    end
  end

  defp render_body(%{body_params: @gif_header <> _rest = body}) do
    Phoenix.HTML.Tag.img_tag(["data:image/gif;base64,", Base.encode64(body)])
  end

  defp render_body(%{body_params: @png_header <> _rest = body}) do
    Phoenix.HTML.Tag.img_tag(["data:image/png;base64,", Base.encode64(body)])
  end

  defp render_body(%{body_params: @jpg_header <> _rest = body}) do
    Phoenix.HTML.Tag.img_tag(["data:image/jpeg;base64,", Base.encode64(body)])
  end

  defp render_body(%{body_params: body}) do
    Phoenix.HTML.Tag.content_tag(
      :pre,
      inspect(body, limit: :infinity, printable_limit: :infinity),
      class: "whitespace-pre select-all"
    )
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
