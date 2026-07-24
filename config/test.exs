import Config

config :utility, cache: Utility.Test.MockCache

config :utility, Utility.Repo,
  database: Path.expand("../utility_test#{System.get_env("MIX_TEST_PARTITION")}.db", __DIR__),
  show_sensitive_data_on_connection_error: true,
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :phoenix, :plug_init_mode, :runtime

config :utility, UtilityWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  server: false

config :utility,
  gendiff_storage_dir: Path.expand("tmp/test")

config :utility, Oban,
  crontab: false,
  queues: false,
  plugins: false

# Print only warnings and errors during test
config :logger, level: :warning
