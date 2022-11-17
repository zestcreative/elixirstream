defmodule UtilityWeb.Router do
  use UtilityWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug UtilityWeb.Plug.GuardianPipeline
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {UtilityWeb.Layouts, :root}
  end

  pipeline :crawlers do
    plug :accepts, ["xml", "json", "webmanifest"]
  end

  pipeline :require_admin do
    plug :is_admin
  end

  pipeline :sink_api do
    plug :accepts, ["json"]
  end

  scope "/", UtilityWeb do
    pipe_through [:browser]

    get "/", PageController, :show
    get "/logout", AuthController, :delete
    delete "/logout", AuthController, :delete

    live_session :default, on_mount: [UtilityWeb.Nav, UtilityWeb.Live.Defaults] do
      live "/tips", TipLive, :index
      live "/tips/new", TipLive, :new
      live "/tips/:id", TipLive, :show
      live "/tips/:id/edit", TipLive, :edit

      live "/about", PageLive, :about
      live "/regex", RegexLive, :new
      live "/regex/:id", RegexLive, :show
      live "/sink", SinkLive, :new
      live "/sink/view/:id", SinkLive, :show
      live "/gendiff", GenDiffLive, :new
    end

    get "/gendiff/:project/:id", GenDiffController, :show
  end

  scope "/", UtilityWeb do
    pipe_through [:sink_api]

    match :*, "/sink/:foo_sink_id", SinkController, :any
  end

  scope "/auth", UtilityWeb do
    pipe_through [:browser]
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  scope "/", UtilityWeb, log: false do
    pipe_through [:crawlers]

    get "/site.webmanifest", PageController, :site_manifest
    get "/browserconfig.xml", PageController, :browserconfig
    get "/healthcheck", PageController, :healthcheck
  end

  scope "/admin" do
    pipe_through [:browser, :require_admin]
    live_dashboard "/dashboard", metrics: UtilityWeb.Telemetry
  end

  defp is_admin(conn, _opts) do
    user = Guardian.Plug.current_resource(conn)

    if Utility.Accounts.admin?(user) do
      conn
    else
      conn
      |> redirect(to: "/")
      |> halt()
    end
  end
end
