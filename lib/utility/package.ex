defmodule Utility.Package do
  use Ecto.Schema
  import Ecto.Changeset
  require Logger

  @primary_key {:name, :string, autogenerate: false}
  schema "packages" do
    field(:versions, {:array, :string})
  end

  @required ~w[name versions]a
  def changeset(struct_or_changeset \\ %__MODULE__{}, attrs) do
    struct_or_changeset
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
