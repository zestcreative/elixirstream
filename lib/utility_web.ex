defmodule UtilityWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels and so on.

  This can be used in your application as:

      use UtilityWeb, :controller
      use UtilityWeb, :html

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths,
    do: ~w[uploads assets fonts svg images site.webmanifest favicon.ico robots.txt]

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: UtilityWeb,
        formats: [:html, :json],
        layouts: [html: UtilityWeb.Layouts]

      import Plug.Conn
      alias UtilityWeb.Router.Helpers, as: Routes

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView, layout: {UtilityWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component
      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component
      import Phoenix.Controller, only: [get_csrf_token: 0, view_module: 1, view_template: 1]
      unquote(html_helpers())
    end
  end

  def html_helpers do
    quote do
      import Phoenix.HTML
      alias Phoenix.LiveView.JS
      alias UtilityWeb.Components
      alias UtilityWeb.Icon
      unquote(verified_routes())
    end
  end

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: UtilityWeb.Endpoint,
        router: UtilityWeb.Router,
        statics: UtilityWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
