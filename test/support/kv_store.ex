defmodule Utility.Test.KVStore do
  @moduledoc """
  A simple KVStore that supports returning stubbed responses at certain hits.
  """
  use GenServer
  @internal_keys ~w[opts stubs hash_get_hits hash_set_hits bust_hits expire_hits keys_hits]a
  @stubable_actions ~w[flush bust hash_get hash_set expire keys]a

  def init(args), do: {:ok, args}

  def start_link(state, opts \\ []) do
    mock_opts = state |> Map.get(:opts, %{}) |> Enum.into([])
    {stubs, mock_opts} = Keyword.pop(mock_opts, :stubs, [])

    state =
      state
      |> Map.put(:stubs, Enum.chunk_every(stubs, 2))
      |> Map.put(:opts, mock_opts)

    GenServer.start_link(__MODULE__, state, opts)
  end

  def handle_call({:hash_get, key, field}, _, state) do
    new_state = Map.update(state, :hash_get_hits, 1, &(&1 + 1))
    value = maybe_stub(:hash_get, new_state, fn -> get_in(new_state, [key, field]) end)

    {:reply, value, new_state}
  end

  def handle_call({:expire, key, ttl}, _, state) do
    new_state = Map.update(state, :expire_hits, 1, &(&1 + 1))

    value =
      maybe_stub(:expire, new_state, fn ->
        if get_in(state, [key]) != nil do
          Process.send_after(self(), {:expire, key}, ttl * 1000)
          "1"
        else
          "0"
        end
      end)

    {:reply, value, new_state}
  end

  def handle_call({:hash_set, key, field, value}, _, state) do
    new_state = Map.update(state, :hash_set_hits, 1, &(&1 + 1))

    exists? =
      maybe_stub(:hash_set, new_state, fn ->
        if get_in(state, [key, field]) != nil, do: "0", else: "1"
      end)

    new_state = Map.update(new_state, key, %{field => value}, &Map.put(&1, field, value))

    {:reply, exists?, new_state}
  end

  def handle_call(:state, _, state), do: {:reply, state, state}

  def handle_call({:keys, term}, _, state) do
    new_state = Map.update(state, :keys_hits, 1, &(&1 + 1))
    value = maybe_stub(:keys, new_state, fn -> list_keys(state, term) end)

    {:reply, value, state}
  end

  def handle_call(:flush, _, state) do
    new_state = Map.update(state, :flush_hits, 1, &(&1 + 1))
    value = maybe_stub(:flush, new_state, fn -> "OK" end)
    keys = list_keys(state, "*")
    new_state = Map.drop(new_state, keys)

    {:reply, value, new_state}
  end

  def handle_call({:bust, key}, _, state) do
    new_state = Map.update(state, :bust_hits, 1, &(&1 + 1))
    value = maybe_stub(:bust, new_state, fn -> "OK" end)
    new_state = Map.drop(new_state, [key])

    {:reply, value, new_state}
  end

  def handle_info({:expire, key}, state) do
    {:noreply, Map.drop(state, [key])}
  end

  defp list_keys(state, term) do
    {:ok, regex} =
      term |> String.replace("?", ".") |> String.replace("*", ".*?") |> Regex.compile()

    state
    |> Map.drop(@internal_keys)
    |> Map.keys()
    |> Enum.filter(&Regex.match?(regex, to_string(&1)))
  end

  for stubable <- @stubable_actions do
    defp find_stub(unquote(stubable), state) do
      Enum.find(state.stubs, fn [{at_hit, _}, _] -> at_hit == :"on_#{unquote(stubable)}_hit" end)
    end
  end

  for stubable <- @stubable_actions do
    defp maybe_stub(unquote(stubable), state, real_value_fn) do
      stub = find_stub(unquote(stubable), state)

      if stub && stub[:"on_#{unquote(stubable)}_hit"] == state[:"#{unquote(stubable)}_hits"] do
        stub[:return]
      else
        real_value_fn.()
      end
    end
  end
end
