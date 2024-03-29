defmodule Utility.TipCatalog.Upvote do
  use Ecto.Schema
  import Ecto.Changeset
  alias Utility.Accounts
  alias Utility.TipCatalog

  @type t :: %__MODULE__{
          user_id: Ecto.UUID.t(),
          tip_id: Ecto.UUID.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tip_upvotes" do
    belongs_to :user, Accounts.User
    belongs_to :tip, TipCatalog.Tip

    timestamps(type: :utc_datetime_usec)
  end

  @optional_fields ~w[user_id tip_id]a

  def changeset(struct_or_changeset, attrs) do
    struct_or_changeset
    |> cast(attrs, @optional_fields)
    |> assoc_constraint(:user)
    |> assoc_constraint(:tip)
    |> unique_constraint([:tip_id, :user_id], message: "is already upvoted by user")
  end
end
