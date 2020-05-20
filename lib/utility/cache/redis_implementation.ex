defmodule Utility.Cache.RedisImplementation do
  @behaviour Utility.Cache

  @function_to_redis %{
    expire: "EXPIRE",
    hash_set: "HSET",
    hash_get: "HSET",
    bust: "DEL",
    keys: "KEYS",
    flush: "FLUSHDB"
  }

  @impl Utility.Cache
  def multi(commands, _opts) do
    Utility.Redix.pipeline(
      Enum.map(commands, fn [function | commands] ->
        [Map.fetch!(@function_to_redis, function) | commands]
      end)
    )
  end

  @impl Utility.Cache
  def expire(key, ttl, _opts) do
    Utility.Redix.command(["EXPIRE", key, ttl])
  end

  @impl Utility.Cache
  def hash_get(key, field, _opts) do
    Utility.Redix.command(["HGET", key, field])
  end

  @impl Utility.Cache
  def hash_set(key, field, value, opts) do
    case Keyword.get(opts, :expires_in) do
      nil ->
        Utility.Redix.command(["HSET", key, field, value])

      expires_in ->
        Utility.Redix.pipeline([["HSET", key, field, value], ["EXPIRE", key, expires_in]])
    end
  end

  @impl Utility.Cache
  def keys(term, _opts), do: Utility.Redix.command(["KEYS", term])

  @impl Utility.Cache
  def bust(key, _opts), do: Utility.Redix.command(["DEL", key])

  @impl Utility.Cache
  def flush(_opts), do: Utility.Redix.command(["FLUSHDB"])
end
