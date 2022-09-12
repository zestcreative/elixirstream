defmodule Utility.Repo.Migrations.AddTipUpvotes do
  use Ecto.Migration

  def change do
    create table("tip_upvotes") do
      add :tip_id, references(:tips, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :nilify_all), null: false
      timestamps()
    end
  end
end
