defmodule Utility.Test.MockCache do
  @moduledoc """
  This cache is designed to be isolated by process and only visible to that process, ideally for
  ExUnit tests since each test is a spawned process. However, this can only be done:
    1) if the test process directly calls start_mock/1 AND does not call the cache through a spawned
        process
    2) if the test spawns a process, then the call stack can receive and pass the cache's pid
        through so it can be used in the mock.

  Supported options:
    stubs: [on_get_hit: 1, return: some_value, on_set_hit: 2, return: some_other_value]

    This option will act like a stub and return a value you want at a certain hit count. For
    example, if you want to return "foo" when the cache.get is hit on the 2nd time, then you would
    provide [stubs: [on_get_hit: 2, return: "foo"]] as options, or tag the test with:
      @tag cache: [stubs: [on_get_hit: 2, return: "foo"]]

  Usage in a test:
    use Utility.DataCase, async: true | false
    # when async = true, the mock_pid is passed into the test context

    test "my indirect test", %{mock_pid: mock_pid} do
      {:ok, result} = MyModule.something_that_spawns_processes(options: [cache_pid: mock_pid])
      # assumes that options is passed all the way to the cache interface
      assert result.stuff
    end

    test "my direct test" do
      {:ok, result} = MyModule.something_that_calls_the_cache_directly()
      assert result.stuff
    end
  """
  alias Utility.Test.KVStore

  @behaviour Utility.Cache
  @global_kv_name Utility.Test.KVStore

  def start_mock(opts \\ []) do
    {async?, opts} = Keyword.pop(opts, :async, false)

    name =
      if async? do
        {:ok, kv_pid} = KVStore.start_link(%{opts: opts})
        Process.put(:mock_cache_pid, kv_pid)
        kv_pid
      else
        @global_kv_name
      end

    {:ok, name}
  end

  @impl Utility.Cache
  def multi(commands, opts) do
    result =
      Enum.map(commands, fn [cmd | args] ->
        elem(apply(__MODULE__, cmd, args ++ [opts]), 1)
      end)

    {:ok, result}
  end

  @impl Utility.Cache
  def hash_get(key, field, opts) do
    {:ok, GenServer.call(mock_cache_pid(opts), {:hash_get, key, field})}
  end

  @impl Utility.Cache
  def hash_set(key, field, value, opts) do
    {:ok, GenServer.call(mock_cache_pid(opts), {:hash_set, key, field, value})}
  end

  @impl Utility.Cache
  def keys(term, opts) do
    {:ok, GenServer.call(mock_cache_pid(opts), {:keys, term})}
  end

  @impl Utility.Cache
  def expire(term, ttl, opts) do
    {:ok, GenServer.call(mock_cache_pid(opts), {:expire, term, ttl})}
  end

  @impl Utility.Cache
  def flush(opts) do
    {:ok, GenServer.call(mock_cache_pid(opts), :flush)}
  end

  @impl Utility.Cache
  def bust(key, opts) do
    {:ok, GenServer.call(mock_cache_pid(opts), {:bust, key})}
  end

  def state!(opts \\ []) do
    GenServer.call(mock_cache_pid(opts), :state)
  end

  def mock_cache_pid(opts) do
    Process.get(:mock_cache_pid) || Keyword.get(opts, :mock_cache_pid, @global_kv_name)
  end
end
