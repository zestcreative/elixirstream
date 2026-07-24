defmodule UtilityWeb.Router do
  use UtilityWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {UtilityWeb.Layouts, :root}
  end

  pipeline :crawlers do
    plug :accepts, ["xml", "json", "webmanifest"]
  end

  pipeline :require_admin do
    plug :basic_auth
  end

  pipeline :sink_api do
    plug :accepts, ["json"]
  end

  scope "/", UtilityWeb do
    pipe_through [:browser]

    get "/", PageController, :show

    live_session :default, on_mount: [UtilityWeb.Nav] do
      live "/about", PageLive, :about
      live "/regex", RegexLive, :new
      live "/regex/:id", RegexLive, :show
      live "/sink", SinkLive, :new
      live "/sink/view/:id", SinkLive, :show
      live "/gendiff", GenDiffLive, :new
    end

    get "/gendiff/api", GenDiffController, :api
    get "/gendiff/api/file", GenDiffController, :api_file
    get "/gendiff/api/changelog", GenDiffController, :api_changelog
    get "/gendiff/:project/:id", GenDiffController, :show
  end

  scope "/", UtilityWeb do
    pipe_through [:sink_api]

    match :*, "/sink/:foo_sink_id", SinkController, :any
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

  defp basic_auth(conn, _opts) do
    auth = Application.get_env(:utility, :admin_auth)
    Plug.BasicAuth.basic_auth(conn, username: auth[:username], password: auth[:password])
  end
end
