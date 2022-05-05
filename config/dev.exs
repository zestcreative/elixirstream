import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :utility, UtilityWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w[--sourcemap=inline --watch]]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w[--watch]]}
  ]

config :utility, Utility.Repo,
  database: "utility_dev",
  stacktrace: true,
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :utility,
  storage_dir: System.tmp_dir!()

# Watch static and templates for browser reloading.
config :utility, UtilityWeb.Endpoint,
  live_reload: [
    iframe_attrs: [class: "hidden"],
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/utility_web/(live|views)/.*(ex)$",
      ~r"lib/utility_web/templates/.*(eex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
