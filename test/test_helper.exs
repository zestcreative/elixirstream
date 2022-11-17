{:ok, _} = Utility.Test.KVStore.start_link(%{}, name: Utility.Test.KVStore)
ExUnit.start()
