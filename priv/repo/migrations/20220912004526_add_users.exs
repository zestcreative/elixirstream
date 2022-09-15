defmodule Utility.Repo.Migrations.AddUsers do
  use Ecto.Migration

  def change do
    create table("users", primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :source, :string, null: false
      add :source_id, :string, null: false

      add :name, :string
      add :avatar, :string
      add :username, :string
      add :twitter, :string

      add :editor_choice, :string, null: false, default: "gui"

      timestamps()
    end

    create unique_index("users", [:source_id, :source])
  end
end
