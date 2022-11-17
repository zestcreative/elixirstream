defmodule Utility.TipCatalog.Tip do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Utility.Accounts
  alias Utility.TipCatalog

  @type t :: %__MODULE__{
          title: String.t(),
          description: String.t(),
          code: String.t(),
          code_image_url: String.t(),
          approved: boolean(),
          upvote_count: pos_integer(),
          twitter_like_count: pos_integer(),
          total_upvote_count: pos_integer(),
          published_at: DateTime.t(),
          twitter_status_id: String.t(),
          contributor_id: Ecto.UUID.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tips" do
    field :title, :string
    field :description, :string
    field :code, :string, default: ""
    field :code_image_url, :string
    field :searchable, Utility.Ecto.TSVectorType
    field :approved, :boolean, default: false
    field :upvote_count, :integer, default: 0
    field :twitter_like_count, :integer, default: 0
    field :total_upvote_count, :integer

    field :published_at, :utc_datetime_usec
    field :twitter_status_id, :string

    belongs_to :contributor, Accounts.User
    has_many :upvotes, TipCatalog.Upvote

    timestamps(type: :utc_datetime_usec)
  end

  @required_fields ~w[approved title description code]a
  @optional_fields ~w[twitter_like_count code_image_url upvote_count published_at contributor_id twitter_status_id]a

  def changeset(struct_or_changeset, attrs) do
    struct_or_changeset
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> assoc_constraint(:contributor)
    |> validate_required(@required_fields)
    |> ensure_published_at()
  end

  defp ensure_published_at(changeset) do
    case get_field(changeset, :published_at) do
      nil -> put_change(changeset, :published_at, DateTime.utc_now())
      _date -> changeset
    end
  end

  def apply(changeset), do: apply_action(changeset, :insert)
end
