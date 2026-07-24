import Config

if config_env() != :test do
  config :utility,
    docker_bin:
      System.find_executable("docker") || System.find_executable("podman") ||
        raise("needs 'docker' installed."),
    gem_bin: System.find_executable("gem") || raise("needs 'gem' installed.")
end

if config_env() == :dev do
  config :utility, UtilityWeb.Endpoint, http: [port: System.get_env("PORT") || 4000]
end

if config_env() == :prod do
  host = System.get_env("HOST")
  fly_host = System.get_env("FLY_APP_NAME") <> ".fly.dev"

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

  config :utility, :admin_auth,
    username: System.fetch_env!("ADMIN_USER"),
    password: System.fetch_env!("ADMIN_PASSWORD")

  config :utility, UtilityWeb.Endpoint,
    http: [port: System.get_env("PORT"), compress: true],
    url: [scheme: "https", host: host || fly_host, port: 443],
    secret_key_base: secret_key_base,
    signing_salt: signing_salt

  # Everything that must persist lives on the Fly volume (STORAGE_DIR): the SQLite
  # database, the DETS cache, and generated gendiff output.
  storage_dir = System.get_env("STORAGE_DIR") || "/storage/utility"
  File.mkdir_p!(storage_dir)

  config :utility,
    gendiff_storage_dir: storage_dir

  # DETS cache on the volume so it survives deploys/restarts.
  config :utility, Utility.Cache.Dets, path: Path.join(storage_dir, "cache.dets")

  config :utility, Utility.Repo,
    database: Path.join(storage_dir, "utility.db"),
    journal_mode: :wal,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")
end
