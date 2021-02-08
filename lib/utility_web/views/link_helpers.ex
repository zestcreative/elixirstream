defmodule UtilityWeb.Views.LinkHelpers do

  def render_page_header(assigns, do: block) do
    Phoenix.View.render(UtilityWeb.LayoutView, "_page_header.html", Map.put(assigns, :header_content, block))
  end

  @doc """
  A shim for Phoenix.HTML.Link.link, but adding attributes for external URLs
  """
  def outbound_link(text, opts \\ [])
  def outbound_link(opts, do: contents) when is_list(opts) do
    outbound_link(contents, opts)
  end
  def outbound_link(text, opts) do
    Phoenix.HTML.Link.link(text, [rel: "nofollow noopener"] ++ opts)
  end
end
