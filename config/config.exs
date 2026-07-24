# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# MDEx syntax highlighting is powered by the lumis engine (compiled into the NIF).
config :mdex_native, syntax_highlighter: :lumis

config :utility,
  ecto_repos: [Utility.Repo],
  generators: [binary_id: true],
  gendiff_storage: Utility.GenDiff.StorageLocal,
  cache: Utility.Cache.Dets,
  cache_version: 3,
  builder_mount: System.tmp_dir!(),
  app_env: Mix.env()

# DETS cache file. Overridden in prod to live on the Fly volume (see runtime.exs).
config :utility, Utility.Cache.Dets, path: "tmp/cache.dets"

config :utility, Oban,
  repo: Utility.Repo,
  engine: Oban.Engines.Lite,
  notifier: Oban.Notifiers.PG,
  plugins: [Oban.Plugins.Pruner],
  queues: [builder: 1]

config :utility, Utility.Repo, migration_timestamps: [type: :utc_datetime]

# Configures the endpoint
config :utility, UtilityWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  secret_key_base: "gJjLZxqBoWFJVdwbLjZe1v2jd2txjpePiZan9WJrhOZsnKhLGftHdjSDHOmDQ+tP",
  signing_salt: "foobar",
  render_errors: [
    formats: [html: UtilityWeb.ErrorHTML, json: UtilityWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Utility.PubSub,
  live_view: [signing_salt: "pni4F/on"]

config :esbuild,
  version: "0.14.41",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --loader:.ttf=file --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.3.5",
  default: [
    args: ~w[
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ],
    cd: Path.expand("../assets", __DIR__)
  ]

config :mime, :types, %{
  "application/xml" => ["xml"],
  "application/manifest+json" => ["webmanifest"]
}

# Report crashes/errors to Sentry via the modern :logger handler. The old
# Sentry.LoggerBackend and the :backends key are both deprecated; the handler is
# attached in Utility.Application.start/2 via Logger.add_handlers(:utility).
config :utility, :logger, [
  {:handler, :sentry_handler, Sentry.LoggerHandler,
   %{config: %{capture_metadata: [:file, :line]}}}
]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# HTTP Basic Auth for the /admin LiveDashboard. Overridden in prod via env vars.
config :utility, :admin_auth, username: "admin", password: "admin"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
