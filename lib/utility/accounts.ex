defmodule Utility.Accounts do
  @moduledoc "Accounts"
  @github_admins ~w[643967]

  alias Utility.Accounts.Query
  alias Utility.Accounts.User
  alias Utility.Repo

  @spec admin?(%User{}) :: boolean()
  def admin?(%{source: :github, source_id: id}) when id in @github_admins, do: true
  def admin?(_), do: false

  @spec update_or_create(map()) ::
    {:create | :update, {:ok, %User{}}} | {:error, Ecto.Changeset.t()}
  def update_or_create(%Ueberauth.Auth{} = auth) do
    case find(to_string(auth.provider), to_string(auth.uid)) do
      nil -> {:create, create(auth)}
      user -> {:update, update(user, auth)}
    end
  end

  @spec find(String.t()) :: nil | %User{}
  @spec find(String.t(), String.t()) :: nil | %User{}
  def find(id), do: Repo.get(User, id)

  def find(source, source_id) do
    source
    |> Query.by_source_and_source_id(source_id)
    |> Repo.one()
  end

  @spec create(map()) :: {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def create(%Ueberauth.Auth{} = auth) do
    %User{}
    |> User.changeset(%{
      source: to_string(auth.provider),
      source_id: to_string(auth.uid),
      name: name_from_auth(auth),
      avatar: avatar_from_auth(auth),
      username: username_from_auth(auth)
    })
    |> Repo.insert()
  end

  @spec update(%User{}, map()) :: {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def update(user, %Ueberauth.Auth{} = auth) do
    user
    |> User.changeset(%{
      name: name_from_auth(auth),
      avatar: avatar_from_auth(auth),
      username: username_from_auth(auth)
    })
    |> Repo.update()
  end

  @spec update_twitter(%User{}, String.t()) ::
          {:ok, %User{}} | {:error, Ecto.Changeset.t() | atom()}
  def update_twitter(nil, _twitter), do: {:error, :not_found}

  def update_twitter(user, twitter) do
    user
    |> User.changeset(%{twitter: twitter})
    |> Repo.update()
  end

  @spec update_editor_choice(%User{}, String.t()) ::
          {:ok, %User{}} | {:error, Ecto.Changeset.t() | atom()}
  def update_editor_choice(user, choice) do
    user
    |> User.changeset(%{editor_choice: choice})
    |> Repo.update()
  end

  defp username_from_auth(%{info: %{nickname: username}}), do: username

  defp name_from_auth(%{info: %{name: name}}) when is_binary(name), do: name

  defp name_from_auth(%{info: %{first_name: first, last_name: last}})
       when is_binary(first) and is_binary(last) and first != "" and last != "" do
    Enum.join([first, last], " ")
  end

  defp name_from_auth(auth), do: username_from_auth(auth)

  defp avatar_from_auth(%{info: %{urls: %{avatar_url: image}}}), do: image
  defp avatar_from_auth(_auth), do: nil
end
