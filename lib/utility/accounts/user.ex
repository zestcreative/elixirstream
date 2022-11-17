defmodule Utility.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          source: :github,
          source_id: String.t(),
          name: String.t(),
          avatar: String.t(),
          username: String.t(),
          twitter: String.t(),
          editor_choice: :gui | :emacs | :vim,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :source, Ecto.Enum, values: [:github]
    field :source_id, :string

    field :name, :string
    field :avatar, :string
    field :username, :string
    field :twitter, :string
    field :editor_choice, Ecto.Enum, values: [:gui, :emacs, :vim]

    timestamps(type: :utc_datetime_usec)
  end

  @required_fields ~w[source source_id]a
  @optional_fields ~w[name avatar username twitter editor_choice]a

  @doc """
  Required: #{inspect(@required_fields)}
  Optional: #{inspect(@optional_fields)}
  """
  def changeset(struct_or_changeset, attrs) do
    struct_or_changeset
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:source_id, :source], message: "already has an account")
  end

  def apply(changeset), do: apply_action(changeset, :insert)
end
