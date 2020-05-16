defmodule UtilityWeb.RegexLive do
  @moduledoc """
  Manage the view of the user's calendar. Defaults to the month view.
  """

  use UtilityWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    UtilityWeb.RegexView.render("show.html", assigns)
  end

end
