defmodule Utility.Accounts.Query do
  import Ecto.Query

  @doc "Find a user by source and source_id"
  def by_source_and_source_id(queryable \\ Utility.Accounts.User, source, source_id) do
    queryable
    |> where([u], u.source == ^source)
    |> where([u], u.source_id == ^source_id)
  end
end
