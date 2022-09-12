defmodule UtilityWeb.AuthController do
  use UtilityWeb, :controller
  alias Utility.Accounts
  require Logger

  plug Ueberauth

  def request(_conn, _params) do
    # The GitHub/Twitter strategy will intercept before hitting this
    raise "whoops"
  end

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    Logger.debug(inspect(fails))

    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: %{provider: :github} = auth}} = conn, _params) do
    conn =
      case Accounts.update_or_create(auth) do
        {:create, {:ok, user}} ->
          conn
          |> put_flash(
            :info,
            "Welcome #{user.name} Be sure to update your profile!"
          )
          |> Utility.Accounts.Guardian.Plug.sign_in(user)

        {:update, {:ok, user}} ->
          conn
          |> put_flash(:info, "Welcome back #{user.name}")
          |> Utility.Accounts.Guardian.Plug.sign_in(user)

        {_, {:error, reason}} ->
          conn |> put_flash(:error, reason)
      end
    redirect(conn, to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: %{provider: :twitter} = auth}} = conn, _params) do
    user = Utility.Accounts.Guardian.Plug.current_resource(conn)

    case Accounts.update_twitter(user, auth.info.nickname) do
      {:ok, user} ->
        conn
        |> put_session(:current_user, user)
        |> put_flash(:info, "Thanks for connecting Twitter")
        |> redirect(to: "/")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Could not connect Twitter")
        |> redirect(to: "/")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out")
    |> Utility.Accounts.Guardian.Plug.sign_out()
    |> redirect(to: "/")
  end
end
