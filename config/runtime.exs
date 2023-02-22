import Config

if config_env() != :test do
  config :utility,
    silicon_bin: System.find_executable("silicon") || raise("needs 'silicon' installed."),
    docker_bin:
      System.find_executable("docker") || System.find_executable("podman") ||
        raise("needs 'docker' installed."),
    gem_bin: System.find_executable("gem") || raise("needs 'gem' installed.")
end

config :utility, Utility.Twitter, publish: System.get_env("TWITTER_PUBLISH", "false") == "true"

if config_env() == :prod do
  host = System.get_env("HOST")
  fly_host = System.get_env("FLY_APP_NAME") <> ".fly.dev"

  config :utility,
    redis_ip6: System.get_env("REDIS_IP6") == "true",
    redis_url:
      System.get_env("REDIS_URL") ||
        raise("""
        environment variable REDIS_URL is missing.
        For example: redis://default:pass@127.0.0.1:6379
        """)

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  signing_salt =
    System.get_env("SIGNING_SALT") ||
      raise """
      environment variable SIGNING_SALT is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  if dsn = System.get_env("SENTRY_DSN") do
    config :sentry,
      dsn: dsn,
      filter: Utility.SentryFilter,
      environment_name: Application.get_env(:utility, :app_env),
      included_environments: [:prod],
      enable_source_code_context: true,
      root_source_code_path: File.cwd!(),
      tags: %{
        env: "production"
      }
  end

  config :ueberauth, Ueberauth.Strategy.Github.OAuth,
    client_id: System.fetch_env!("GITHUB_CLIENT_ID"),
    client_secret: System.fetch_env!("GITHUB_CLIENT_SECRET")

  config :ueberauth, Ueberauth.Strategy.Twitter.OAuth,
    consumer_key: System.get_env("TWITTER_LOGIN_CONSUMER_KEY"),
    consumer_secret: System.get_env("TWITTER_LOGIN_CONSUMER_SECRET")

  config :utility, Utility.Twitter.Client,
    consumer_key: System.get_env("TWITTER_CONSUMER_KEY"),
    consumer_secret: System.get_env("TWITTER_CONSUMER_SECRET"),
    token: System.get_env("TWITTER_TOKEN"),
    token_secret: System.get_env("TWITTER_TOKEN_SECRET")

  config :utility, UtilityWeb.Endpoint,
    http: [port: System.get_env("PORT"), compress: true],
    url: [scheme: "https", host: host || fly_host, port: 443],
    secret_key_base: secret_key_base,
    signing_salt: signing_salt

  if storage_dir = System.get_env("STORAGE_DIR") do
    File.mkdir_p(storage_dir)
    config :utility, gendiff_storage_dir: storage_dir
    config :utility, tip_storage_dir: storage_dir
  end

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: postgres://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :utility, Utility.Repo,
    # ssl: true,
    url: database_url,
    socket_options: maybe_ipv6,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :utility, Utility.Silicon,
    fonts: Utility.Silicon.fonts(),
    themes: Utility.Silicon.themes()
end
