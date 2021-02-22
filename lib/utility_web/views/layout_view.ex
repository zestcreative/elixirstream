defmodule UtilityWeb.LayoutView do
  use UtilityWeb, :view

  @doc """
  A shim for Phoenix.HTML.Link.link, but adding a class if currently on the page
  """
  def active_link(conn, route, text, opts)

  def active_link(conn, route, opts, do: contents) when is_list(opts) do
    active_link(conn, route, contents, opts)
  end

  def active_link(conn, route, text, opts) do
    to = Keyword.fetch!(opts, :to)

    if String.starts_with?(conn.request_path, to) do
      {class, opts} = Keyword.pop(opts, :class, "")
      class = "#{class} active"

      Phoenix.LiveView.Helpers.live_redirect(
        text,
        opts ++
          [
            "@click": "$dispatch('navigate', '#{route}')",
            class: class,
            ":class": "{'active': currentRoute === '#{route}', '': currentRoute !== '#{route}'}"
          ]
      )
    else
      Phoenix.HTML.Link.link(text, opts)
    end
  end
end
