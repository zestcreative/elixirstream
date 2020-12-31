import Config

config :utility, cache: Utility.Test.MockCache

config :utility, Utility.Repo,
  database: "utility_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :utility, UtilityWeb.Endpoint,
  http: [port: 4002],
  server: false

config :utility,
  storage_dir: Path.expand("tmp/test")

config :utility, Oban,
  crontab: false,
  queues: false,
  plugins: false

# Print only warnings and errors during test
config :logger, level: :warn
