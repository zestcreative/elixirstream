defmodule Utility.Package.Updater do
  use GenServer
  require Logger
  @update_every :timer.hours(12)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    Logger.debug("Starting Hex.pm/RubyGem version updater")
    Process.send_after(self(), :update, @update_every)
    {:ok, [], {:continue, :update}}
  end

  def handle_continue(:update, state) do
    update()
    {:noreply, state, :hibernate}
  end

  def handle_info(:update, state) do
    update()
    {:noreply, state, :hibernate}
  end

  def update() do
    Logger.debug("Updating Hex.pm version store")
    Utility.Hex.cache_versions(:all)
    Logger.debug("Updating RubyGem version store")
    Utility.Gem.cache_versions(:all)
    Process.send_after(self(), :update, @update_every)
  end
end
