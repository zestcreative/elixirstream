defmodule Utility.TipCatalog.Query do
  import Ecto.Query
  alias Utility.TipCatalog.Tip

  def where_id(queryable \\ Tip, id) do
    queryable
    |> where([q], q.id == ^id)
  end

  def where_contributor_id(queryable \\ Tip, id) do
    queryable
    |> where([q], q.contributor_id == ^id)
  end

  def where_ids(queryable \\ Tip, ids) do
    queryable
    |> where([q], q.id in ^ids)
  end

  def where_mine_or_published(queryable \\ Tip, user_id) do
    queryable
    |> where([q], q.contributor_id == ^user_id or q.published_at < ^DateTime.utc_now())
  end

  def where_published(queryable \\ Tip) do
    now = DateTime.utc_now()

    queryable
    |> where([q], q.published_at < ^now)
  end

  def where_published_at_gte(queryable \\ Tip, date) do
    queryable
    |> where([q], q.published_at >= ^date)
  end

  def return(queryable \\ Tip, fields) do
    select(queryable, ^fields)
  end

  def search(queryable \\ Tip, search_terms) do
    queryable
    |> where(
      [q],
      fragment("? @@ websearch_to_tsquery('english', ?)", q.searchable, ^search_terms)
    )
    # Quarto doesn't support order by fragments :(
    # |> Ecto.Query.order_by([q], asc: fragment("ts_rank_cd(?, to_tsquery('english', ?), 32) AS rank", q.searchable, ^search_terms))
    |> Ecto.Query.order_by([q], desc: q.published_at)
    |> limit(10)
  end

  def approved(queryable \\ Tip) do
    where(queryable, [q], q.approved == true)
  end

  def not_approved(queryable \\ Tip) do
    where(queryable, [q], q.approved == false)
  end

  def order_by_latest(queryable \\ Tip) do
    order_by(queryable, [q], desc: q.published_at)
  end

  def order_by_unapproved(queryable \\ Tip) do
    order_by(queryable, [q], asc: q.approved)
  end

  def order_by_upvotes(queryable \\ Tip) do
    queryable
    |> order_by([q], desc: q.total_upvote_count)
    |> order_by_latest()
  end

  def preload_contributor(queryable \\ Tip) do
    if has_named_binding?(queryable, :contributor) do
      queryable
    else
      queryable
      |> join(:left, [q], c in assoc(q, :contributor), as: :contributor)
      |> preload([_q, contributor: c], contributor: c)
    end
  end

  def upvoted_by(queryable \\ Tip, user_id) do
    if has_named_binding?(queryable, :upvotes) do
      queryable
    else
      queryable
      |> join(:left, [q], u in assoc(q, :upvotes), as: :upvotes)
      |> preload([_q, upvotes: u], upvotes: u)
    end
    |> where([upvotes: u], u.user_id == ^user_id)
  end
end
