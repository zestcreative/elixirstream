defmodule Utility.Repo.Migrations.AddTips do
  use Ecto.Migration

  def change do
    create table("tips") do
      add :title, :text, null: false
      add :description, :text, null: false
      add :code, :text, null: false
      add :code_image_url, :string
      add :published_at, :utc_datetime
      add :approved, :boolean, null: false, default: false
      add :twitter_status_id, :string
      add :twitter_like_count, :integer, null: false, default: 0
      add :upvote_count, :integer, null: false, default: 0

      add :contributor_id, references(:users, on_delete: :nilify_all), null: false

      timestamps()
    end

    execute """
            ALTER TABLE tips
            ADD COLUMN total_upvote_count integer
             GENERATED ALWAYS AS (twitter_like_count + upvote_count) STORED
            """,
            """
            ALTER TABLE tips DROP COLUMN total_upvote_count
            """

    execute """
            ALTER TABLE tips
            ADD COLUMN searchable tsvector
             GENERATED ALWAYS AS (to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, ''))) STORED
            """,
            """
            ALTER TABLE tips DROP COLUMN searchable
            """

  end
end
