defmodule UtilityWeb.Live.Defaults do
  @moduledoc "Helpers to assist with loading the user from the session into the socket"

  import Phoenix.LiveView
  alias Ecto.Changeset

  @claims %{"typ" => "access"}
  @token_key "guardian_default_token"

  def defaults(socket, session) do
    socket
    |> assign(searching: false, search_changeset: search_changeset(%{}))
    |> load_user(session)
  end

  @search_types %{module: :string, q: :string}
  def search_changeset(params) do
    {%{}, @search_types}
    |> Changeset.cast(params, Map.keys(@search_types))
    |> Changeset.validate_length(:q, max: 75)
  end

  def require_user(socket) do
    if socket.assigns.current_user.id do
      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Not logged in")
       |> redirect(to: "/")}
    end
  end

  def load_user(socket, %{@token_key => token}) do
    Phoenix.LiveView.assign_new(socket, :current_user, fn ->
      with {:ok, claims} <-
             Guardian.decode_and_verify(Utility.Accounts.Guardian, token, @claims),
           {:ok, user} <- Utility.Accounts.Guardian.resource_from_claims(claims) do
        user
      else
        _ -> %Utility.Accounts.User{}
      end
    end)
  end

  def load_user(socket, _) do
    assign_new(socket, :current_user, fn -> %Utility.Accounts.User{} end)
  end
end
