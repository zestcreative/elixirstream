defmodule Utility.Repo.Migrations.AddTipUpvotes do
  use Ecto.Migration

  def change do
    create table("tip_upvotes", primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tip_id, references(:tips, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false
      timestamps()
    end
  end
end
