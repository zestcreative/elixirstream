defmodule Utility.Repo.Migrations.AddTipsIndex do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index("tips", ["searchable"],
             name: :tips_searchable_index,
             using: "GIN",
             concurrently: true
           )
  end
end
