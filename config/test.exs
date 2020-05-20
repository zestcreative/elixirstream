use Mix.Config

config :utility, cache: Utility.Test.MockCache

config :floki, :html_parser, Floki.HTMLParser.FastHtml

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :utility, UtilityWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
