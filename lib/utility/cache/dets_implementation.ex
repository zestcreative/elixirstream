defmodule Utility.Cache.Dets do
  @moduledoc """
  DETS-backed cache implementing the `Utility.Cache` behaviour, replacing the Redis
  adapter.

  A single owner process (this GenServer) keeps the DETS table open for the life of
  the application; the read/write callbacks hit `:dets` directly by table name, so
  they don't serialize through the GenServer (the ETS/DETS owner pattern).

  Records are `{key, %{field => value}, expires_at}`, mapping Redis hashes and TTLs
  onto DETS. `expires_at` is a unix timestamp (seconds) or `:infinity`.

  Expiry is lazy — checked on read. ponytail: no periodic sweeper; a stale entry
  costs one record until its key is next read or overwritten. Add a sweep only if
  the file grows unbounded (it won't for the current regex-permalink usage).

  On Fly.io the DETS file lives on the mounted volume (see `STORAGE_DIR`) so it
  survives deploys and restarts.
  """
  use GenServer
  @behaviour Utility.Cache

  @table :utility_cache

  # --- Owner process: keeps the DETS table open ---

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_opts) do
    path = path()
    File.mkdir_p!(Path.dirname(path))
    {:ok, @table} = :dets.open_file(@table, file: String.to_charlist(path), type: :set)
    {:ok, %{}}
  end

  @impl GenServer
  def terminate(_reason, _state), do: :dets.close(@table)

  defp path do
    Application.get_env(:utility, __MODULE__)[:path] || "tmp/cache.dets"
  end

  # --- Utility.Cache behaviour ---
  # Callable from any process: :dets is accessible by table name once the owner
  # has opened it.

  @impl Utility.Cache
  def multi(commands, opts) do
    results =
      Enum.map(commands, fn [fun | args] ->
        {:ok, result} = apply(__MODULE__, fun, args ++ [opts])
        result
      end)

    {:ok, results}
  end

  @impl Utility.Cache
  def hash_get(key, field, _opts) do
    case fetch(key) do
      {:ok, fields} -> {:ok, Map.get(fields, field)}
      :error -> {:ok, nil}
    end
  end

  @impl Utility.Cache
  def hash_set(key, field, value, opts) do
    fields =
      case fetch(key) do
        {:ok, existing} -> existing
        :error -> %{}
      end

    expires_at =
      case Keyword.get(opts, :expires_in) do
        nil -> current_expiry(key)
        seconds -> now() + seconds
      end

    :dets.insert(@table, {key, Map.put(fields, field, value), expires_at})
    {:ok, value}
  end

  @impl Utility.Cache
  def expire(key, ttl, _opts) do
    case :dets.lookup(@table, key) do
      [{^key, fields, _}] -> :dets.insert(@table, {key, fields, now() + ttl})
      [] -> :ok
    end

    {:ok, ttl}
  end

  @impl Utility.Cache
  def keys(pattern, _opts) do
    regex = Regex.compile!("^" <> String.replace(Regex.escape(pattern), "\\*", ".*") <> "$")

    matched =
      :dets.foldl(
        fn {key, _fields, _expires_at}, acc ->
          if Regex.match?(regex, to_string(key)), do: [key | acc], else: acc
        end,
        [],
        @table
      )

    {:ok, matched}
  end

  @impl Utility.Cache
  def bust(key, _opts) do
    :dets.delete(@table, key)
    {:ok, 1}
  end

  @impl Utility.Cache
  def flush(_opts) do
    :dets.delete_all_objects(@table)
    {:ok, "OK"}
  end

  # --- helpers ---

  defp fetch(key) do
    case :dets.lookup(@table, key) do
      [{^key, fields, expires_at}] ->
        if expired?(expires_at) do
          :dets.delete(@table, key)
          :error
        else
          {:ok, fields}
        end

      [] ->
        :error
    end
  end

  defp current_expiry(key) do
    case :dets.lookup(@table, key) do
      [{^key, _fields, expires_at}] -> expires_at
      [] -> :infinity
    end
  end

  defp expired?(:infinity), do: false
  defp expired?(expires_at), do: now() >= expires_at

  defp now, do: System.system_time(:second)
end
