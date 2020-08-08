import Config

host = System.get_env("HOST")

heroku_host =
  if heroku_app_name = System.get_env("HEROKU_APP_NAME") do
    heroku_app_name <> ".herokuapp.com"
  end

config :utility, UtilityWeb.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [scheme: "https", host: host || heroku_host, port: 443]
