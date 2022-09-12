defmodule Utility.Repo.Migrations.AddTipUpvoteIndex do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create unique_index(:tip_upvotes, [:tip_id, :user_id], concurrently: true)
  end
end
