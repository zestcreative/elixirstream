defmodule UtilityWeb.AuthController do
  use UtilityWeb, :controller
  alias Utility.Accounts
  require Logger

  plug Ueberauth

  def request(_conn, _params) do
    # The GitHub/Twitter strategy will intercept before hitting this
    raise "invalid authentication"
  end

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    Logger.warn(inspect(fails))

    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/tips")
  end

  def callback(%{assigns: %{ueberauth_auth: %{provider: :github} = auth}} = conn, _params) do
    case Accounts.update_or_create(auth) do
      {action, {:ok, user}} ->
        conn
        |> put_flash(:info, sign_in_message(action, user))
        |> Utility.Accounts.Guardian.Plug.sign_in(user)
        |> redirect(to: "/tips")

      {_, {:error, reason}} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/tips")
    end
  end

  def callback(%{assigns: %{ueberauth_auth: %{provider: :twitter} = auth}} = conn, _params) do
    user = Utility.Accounts.Guardian.Plug.current_resource(conn)

    case Accounts.update_twitter(user, auth.info.nickname) do
      {:ok, user} ->
        conn
        |> put_session(:current_user, user)
        |> put_flash(:info, "Thanks for connecting Twitter")
        |> redirect(to: "/tips")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Could not connect Twitter")
        |> redirect(to: "/tips")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out")
    |> Utility.Accounts.Guardian.Plug.sign_out()
    |> redirect(to: "/tips")
  end

  def sign_in_message(:create, user) do
    "Welcome #{user.name}. Be sure to update your profile!"
  end

  def sign_in_message(:update, user) do
    "Welcome back #{user.name}"
  end
end
