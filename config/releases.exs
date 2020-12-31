import Config

host = System.get_env("HOST")

_require_auth_user = System.fetch_env!("AUTH_USER")
_require_auth_pass = System.fetch_env!("AUTH_PASS")

storage_dir = Path.join([System.user_home!(), ".cache", "utility"])
File.mkdir_p!(storage_dir)

config :utility,
  storage_dir: storage_dir

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

if dsn = System.get_env("SENTRY_DSN") do
  config :sentry,
    dsn: dsn,
    environment_name: Application.get_env(:utility, :app_env),
    included_environments: [:prod],
    enable_source_code_context: true,
    root_source_code_path: File.cwd!(),
    tags: %{
      env: "production"
    }
end

config :utility, UtilityWeb.Endpoint,
  http: [port: {:system, "PORT"}, compress: true],
  url: [scheme: "https", host: host, port: 443],
  secret_key_base: secret_key_base

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: postgres://USER:PASS@HOST/DATABASE
    """

docker_bin =
  System.find_executable("docker") ||
    raise "needs 'docker' installed."

config :utility,
  docker_bin: docker_bin

config :utility, Utility.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
