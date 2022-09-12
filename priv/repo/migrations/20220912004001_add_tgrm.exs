defmodule Utility.Repo.Migrations.AddTgrm do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    execute(
      "CREATE EXTENSION IF NOT EXISTS \"pg_trgm\"",
      "DROP EXTENSION IF EXISTS \"pg_trgm\""
    )
  end
end
