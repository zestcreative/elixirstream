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
  defp render_body(%{format: :json, body_params: body}) do
    case Jason.encode(body, pretty: true) do
      {:ok, parsed} -> pre(parsed)
      {:error, _} -> render_body(%{body_params: body})
    end
  end

  defp render_body(%{body_params: @gif_header <> _rest = body}), do: image("gif", body)
  defp render_body(%{body_params: @png_header <> _rest = body}), do: image("png", body)
  defp render_body(%{body_params: @jpg_header <> _rest = body}), do: image("jpeg", body)

  defp render_body(%{body_params: body}) do
    pre(inspect(body, limit: :infinity, printable_limit: :infinity))
  end

  # Build safe HTML directly (no phoenix_html_helpers). html_escape/1 returns
  # already-escaped iodata; the tags and base64 payload contain no HTML metachars.
  defp pre(content) do
    {:safe, escaped} = Phoenix.HTML.html_escape(content)
    {:safe, [~s(<pre class="whitespace-pre select-all">), escaped, "</pre>"]}
  end

  defp image(type, body) do
    {:safe, [~s(<img src="data:image/), type, ";base64,", Base.encode64(body), ~s(">)]}
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
