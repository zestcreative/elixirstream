# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :utility,
  docker_bin: System.find_executable("docker"),
  ecto_repos: [Utility.Repo],
  generators: [binary_id: true],
  storage: Utility.Storage.LocalImplementation,
  cache: Utility.Cache.RedisImplementation,
  cache_version: 1,
  app_env: Mix.env()

config :utility, Oban,
  repo: Utility.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [builder: 1]

# Configures the endpoint
config :utility, UtilityWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "gJjLZxqBoWFJVdwbLjZe1v2jd2txjpePiZan9WJrhOZsnKhLGftHdjSDHOmDQ+tP",
  render_errors: [view: UtilityWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Utility.PubSub,
  live_view: [signing_salt: "pni4F/on"]

config :utility, :basic_auth,
  auth_user: System.get_env("AUTH_USER", "admin"),
  auth_pass: System.get_env("AUTH_PASS", "admin")

config :mime, :types, %{
  "application/xml" => ["xml"],
  "application/manifest+json" => ["webmanifest"]
}

config :logger,
  backends: [:console, Sentry.LoggerBackend]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

redis_url = URI.parse(System.get_env("REDIS_URL") || "redis://127.0.0.1:6379")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
