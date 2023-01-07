defmodule Utility.Repo.Migrations.AddMastodonToTips do
  use Ecto.Migration

  def change do
    alter table("tips") do
      add :fedi_like_count, :integer, default: 0, null: false
      add :fedi_status_id, :string
    end

    alter table("users") do
      remove :editor_choice
      add :fediverse, :string
    end
  end
end
