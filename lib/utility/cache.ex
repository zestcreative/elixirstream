defmodule Utility.Cache do
  @moduledoc """
  Interface for caching data. This serves as the layer between the real implementations and mock
  implementations, and to hide adapters from application code.
  """

  defmodule Error do
    defexception [:message, :original_error]
  end

  @callback multi(list(), Keyword.t()) :: {:ok, list(any())} | {:error, any()}

  @callback hash_get(any(), any(), Keyword.t()) :: {:ok, any()} | {:error, any()}
  @callback hash_set(any(), any(), any(), Keyword.t()) :: {:ok, any()} | {:error, any()}

  @callback keys(any(), Keyword.t()) :: {:ok, list(any())} | {:error, any()}
  @callback bust(any(), Keyword.t()) :: {:ok, any()} | {:error, any()}
  @callback flush(Keyword.t()) :: {:ok, any()} | {:error, any()}
  @callback expire(any(), integer(), Keyword.t()) :: {:ok, any()} | {:error, any()}

  @module Application.compile_env(:utility, :cache)

  @spec multi(any(), Keyword.t()) :: {:ok, list(any())} | {:error, any()}
  def multi(term, opts \\ []), do: @module.multi(term, opts)

  @spec expire(any(), integer(), Keyword.t()) :: {:ok, list(any())} | {:error, any()}
  def expire(term, ttl, opts \\ []), do: @module.expire(term, ttl, opts)

  @spec keys(any(), Keyword.t()) :: {:ok, list(any())} | {:error, any()}
  def keys(term, opts \\ []), do: @module.keys(term, opts)

  @spec keys!(Keyword.t()) :: list(any()) | no_return()
  def keys!(term, opts \\ []) do
    case keys(term, opts) do
      {:ok, value} ->
        value

      {:error, error} ->
        raise Error, message: "Error when getting keys", original_error: error
    end
  end

  @spec flush(Keyword.t()) :: {:ok, any()} | {:error, any()}
  def flush(opts \\ []), do: @module.flush(opts)

  @spec flush!(Keyword.t()) :: any() | no_return()
  def flush!(opts \\ []) do
    case flush(opts) do
      {:ok, value} ->
        value

      {:error, error} ->
        raise Error, message: "Error when flushing", original_error: error
    end
  end

  @spec bust(binary(), Keyword.t()) :: {:ok, any()} | {:error, any()}
  def bust(key, opts \\ []), do: @module.bust(key, opts)

  @spec bust!(binary(), Keyword.t()) :: any() | no_return()
  def bust!(key, opts \\ []) do
    case bust(key, opts) do
      {:ok, value} ->
        value

      {:error, error} ->
        raise Error, message: "Error when busting #{key}", original_error: error
    end
  end

  @spec hash_get(binary(), binary()) :: {:ok, any()} | {:error, any()}
  def hash_get(key, field, opts \\ []), do: @module.hash_get(key, field, opts)

  @spec hash_get!(binary(), binary()) :: any() | no_return()
  def hash_get!(key, field, opts \\ []) do
    case hash_get(key, field, opts) do
      {:ok, value} ->
        value

      {:error, error} ->
        raise Error, message: "Error when retrieving #{key}:#{field}", original_error: error
    end
  end

  @spec hash_set(binary(), binary(), any(), Keyword.t()) :: {:ok, any()} | {:error, any()}
  def hash_set(key, field, value, options \\ []), do: @module.hash_set(key, field, value, options)

  @spec hash_set!(binary(), binary(), any(), Keyword.t()) :: any() | no_return()
  def hash_set!(key, field, value, options \\ []) do
    case hash_set(key, field, value, options) do
      {:ok, value} ->
        value

      {:error, error} ->
        raise Error,
          message: "Error when setting #{key}:#{field} to #{value}",
          original_error: error
    end
  end
end
