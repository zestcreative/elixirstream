defmodule Utility.TipCatalog do
  alias Utility.TipCatalog.{Query, Tip, Upvote}
  alias Utility.Accounts.{User}
  alias Utility.{Silicon, Storage, Repo}
  alias Phoenix.PubSub
  import Utility.Accounts, only: [admin?: 1]
  require Ecto.Query

  @tip_topic "tips"

  @spec find_tip(String.t()) :: nil | %Tip{}
  def find_tip(id) do
    Tip
    |> Query.preload_contributor()
    |> Repo.get(id)
  end

  @default_list_opts [
    by_latest: false,
    by_upvotes: false,
    limit: false,
    order: false,
    not_approved: false,
    only_not_approved: false,
    unpublished: false,
    paginate: false,
    stream: false
  ]
  @spec list_tips(Keyword.t(), Ecto.Queryable.t()) :: list(%Tip{}) | Quarto.Page.t()
  def list_tips(opts \\ [], queryable \\ Tip)

  def list_tips(opts, queryable) do
    opts = Keyword.merge(@default_list_opts, opts)
    {paginate, opts} = Keyword.pop(opts, :paginate)
    {stream, opts} = Keyword.pop(opts, :stream)
    {limit, opts} = Keyword.pop(opts, :limit)

    queryable = opts |> Enum.reduce(queryable, &do_list_tips/2)
    queryable = do_list_tips({:limit, limit}, queryable)

    cond do
      stream ->
        queryable
        |> Repo.stream(opts)
        |> Stream.chunk_every(opts[:max_rows])
        |> Stream.flat_map(fn chunk -> tip_preloads(chunk) end)

      paginate ->
        queryable
        |> Query.preload_contributor()
        |> Repo.paginate(opts)

      true ->
        queryable
        |> Query.preload_contributor()
        |> Repo.all()
    end
  end

  defp do_list_tips({:approved, true}, queryable), do: Query.approved(queryable)
  defp do_list_tips({:not_approved, false}, queryable), do: Query.approved(queryable)
  defp do_list_tips({:not_approved, true}, queryable), do: queryable
  defp do_list_tips({:only_not_approved, true}, queryable), do: Query.not_approved(queryable)

  defp do_list_tips({:published_at_gte, %DateTime{} = date}, queryable),
    do: Query.where_published_at_gte(queryable, date)

  defp do_list_tips({:unpublished, id}, queryable) when is_binary(id),
    do: Query.where_mine_or_published(queryable, id)

  defp do_list_tips({:unpublished, true}, queryable), do: queryable
  defp do_list_tips({:unpublished, false}, queryable), do: Query.where_published(queryable)
  defp do_list_tips({_, false}, queryable), do: queryable
  defp do_list_tips({:by_latest, true}, queryable), do: Query.order_by_latest(queryable)
  defp do_list_tips({:by_upvotes, true}, queryable), do: Query.order_by_upvotes(queryable)
  defp do_list_tips({:by_not_approved, true}, queryable), do: Query.order_by_unapproved(queryable)
  defp do_list_tips({:search, q}, queryable), do: Query.search(queryable, q)
  defp do_list_tips({:limit, limit}, queryable), do: Ecto.Query.limit(queryable, ^limit)
  defp do_list_tips({:order, order}, queryable), do: Ecto.Query.order_by(queryable, ^order)
  defp do_list_tips(_opt, queryable), do: queryable

  def tip_preloads(queryable) do
    Repo.preload(queryable, :contributor)
  end

  def delete_tip_for_user(tip_id, user) do
    if admin?(user) do
      Tip |> Query.where_id(tip_id) |> Repo.delete_all()
    else
      Tip |> Query.where_id(tip_id) |> Query.where_contributor_id(user.id) |> Repo.delete_all()
    end
  end

  def downvote_tip(tip_id, user) when is_binary(tip_id) do
    Tip
    |> Repo.get_by(id: tip_id)
    |> downvote_tip(user)
  end

  def downvote_tip(nil, _user), do: {:error, :tip_not_found}
  def downvote_tip(_tip, nil), do: {:error, :user_not_found}
  def downvote_tip(%Tip{contributor_id: user_id}, %User{id: user_id}), do: {:ok, nil}

  def downvote_tip(%Upvote{} = upvote, tip) do
    case Repo.delete(upvote) do
      {:ok, _upvote} ->
        {_, [%{upvote_count: count}]} =
          tip.id
          |> Query.where_id()
          |> Query.return([:upvote_count])
          |> Repo.update_all(inc: [upvote_count: -1])

        updated_tip = tip_preloads(%{tip | upvote_count: count})
        PubSub.broadcast(Utility.PubSub, @tip_topic, [:tip, :update, updated_tip])
        {:ok, updated_tip}

      _error ->
        {:ok, nil}
    end
  end

  def downvote_tip(tip, user) do
    Upvote
    |> Repo.get_by(tip_id: tip.id, user_id: user.id)
    |> downvote_tip(tip)
  end

  @spec upvote_tip(String.t(), %User{}) :: {:ok, %Upvote{}} | {:error, Ecto.Changeset.t()}
  def upvote_tip(tip_id, user) when is_binary(tip_id) do
    Tip
    |> Repo.get_by(id: tip_id)
    |> upvote_tip(user)
  end

  def upvote_tip(nil, _user), do: {:error, :not_found}
  def upvote_tip(_tip, nil), do: {:error, :not_found}
  def upvote_tip(%{contributor_id: user_id}, %{id: user_id}), do: {:ok, nil}

  def upvote_tip(tip, user) do
    %Upvote{}
    |> Upvote.changeset(%{user_id: user.id, tip_id: tip.id})
    |> Repo.insert()
    |> case do
      {:ok, _} ->
        {_, [%{upvote_count: count}]} =
          tip.id
          |> Query.where_id()
          |> Query.return([:upvote_count])
          |> Repo.update_all(inc: [upvote_count: 1])

        updated_tip = tip_preloads(%{tip | upvote_count: count})
        PubSub.broadcast(Utility.PubSub, @tip_topic, [:tip, :update, updated_tip])
        {:ok, updated_tip}

      error ->
        error
    end
  end

  @spec tips_upvoted_by_user(%User{}, Keyword.t()) :: list(String.t())
  def tips_upvoted_by_user(nil, _opts), do: []
  def tips_upvoted_by_user(%{id: nil}, _opts), do: []

  def tips_upvoted_by_user(user, where_id: tip_ids) do
    Tip
    |> Query.where_ids(tip_ids)
    |> Query.upvoted_by(user.id)
    |> Query.return([:id])
    |> Repo.all()
    |> Enum.map(& &1.id)
  end

  @spec add_image_to_tip(%Tip{}, String.t()) :: {:ok, %Tip{}} | {:error, Ecto.Changeset.t()}
  def add_image_to_tip(%{id: nil} = tip, key) do
    case Storage.url(key, expires_in: :timer.minutes(5), grant_read: :public_read) do
      {:ok, url} -> {:ok, %{tip | code_image_url: url}}
      error -> error
    end
  end

  def add_image_to_tip(%{id: id} = tip, key) when is_binary(id) do
    tip
    |> Tip.changeset(%{code_image_url: key})
    |> Repo.update()
  end

  def add_twitter_status_id(tip, twitter_status_id) do
    tip
    |> Tip.changeset(%{twitter_status_id: twitter_status_id})
    |> Repo.update()
  end

  @spec create_tip(map()) :: {:ok, %Tip{}}
  def create_tip(attrs) do
    %Tip{}
    |> Tip.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, tip} ->
        tip = tip_preloads(tip)
        PubSub.broadcast(Utility.PubSub, @tip_topic, [:tip, :new, tip])
        {:ok, tip}

      error ->
        error
    end
  end

  @spec update_tip(%Tip{}, map()) :: {:ok, %Tip{}} | {:error, Ecto.Changeset.t()}
  def update_tip(tip, attrs) do
    tip
    |> Tip.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, tip} ->
        tip = tip_preloads(tip)
        PubSub.broadcast(Utility.PubSub, @tip_topic, [:tip, :update, tip])
        {:ok, tip}

      error ->
        error
    end
  end

  @spec approve_tip(%Tip{}) :: {:ok, %Tip{}}
  def approve_tip(tip_id) when is_binary(tip_id), do: tip_id |> find_tip() |> approve_tip()

  def approve_tip(tip) do
    with {:ok, tip} <- tip |> Tip.changeset(%{approved: true}) |> Repo.update(),
         {:ok, _} <-
           %{tip_id: tip.id}
           |> Utility.Workers.PublishTip.new(scheduled_at: tip.published_at)
           |> Oban.insert() do
      tip = tip_preloads(tip)
      PubSub.broadcast(Utility.PubSub, @tip_topic, [:tip, :approve, tip])
      {:ok, tip}
    else
      error ->
        error
    end
  end

  @codeshot_upload_folder "codeshots"
  def generate_codeshot(tip) do
    with {:ok, file} <- Silicon.generate(tip),
         tmp_id <- Path.basename(file),
         {:ok, %{body: %{key: key}}} <-
           Storage.upload(file, Path.join(@codeshot_upload_folder, tip.id || tmp_id)),
         {:ok, tip} <- add_image_to_tip(tip, key) do
      {:ok, tip, file}
    end
  end
end
