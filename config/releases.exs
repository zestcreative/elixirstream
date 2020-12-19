import Config

host = System.get_env("HOST")

_require_auth_user = System.fetch_env!("AUTH_USER")
_require_auth_pass = System.fetch_env!("AUTH_PASS")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :utility, UtilityWeb.Endpoint,
  http: [port: {:system, "PORT"}, compress: true],
  url: [scheme: "https", host: host, port: 443],
  secret_key_base: secret_key_base
