import Config

config :utility, cache: Utility.Test.MockCache

config :utility, Utility.Repo,
  database: "utility_test#{System.get_env("MIX_TEST_PARTITION")}",
  show_sensitive_data_on_connection_error: true,
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

if System.get_env("CI") do
  config :utility, Utility.Repo,
    hostname: System.get_env("DATABASE_HOST"),
    username: System.get_env("DATABASE_USER"),
    password: System.get_env("DATABASE_PASS")
end

config :phoenix, :plug_init_mode, :runtime

config :utility, UtilityWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  server: false

config :utility,
  gendiff_storage_dir: Path.expand("tmp/test"),
  tip_storage_dir: Path.expand("tmp/test")

config :utility, Oban,
  crontab: false,
  queues: false,
  plugins: false

# Print only warnings and errors during test
config :logger, level: :warning

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
