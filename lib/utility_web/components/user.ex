defmodule UtilityWeb.Components.User do
  @moduledoc false
  use UtilityWeb, :component
  import Utility.Accounts, only: [admin?: 1]

  attr :current_user, :any, required: true

  def login(assigns) do
    ~H"""
    <%= unless @current_user.id do %>
      <.link href={~p"/auth/github"} class="ml-6 inline-flex items-center px-3 py-2 border border-transparent shadow-sm text-sm leading-4 font-medium rounded-md text-white bg-black hover:bg-brand-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand-500">
        <Icon.github class="text-white -ml-0.5 mr-2 h-4 w-4" /> Login
      </.link>
    <% end %>
    """
  end

  attr :current_user, :any, required: true
  attr :class, :string, default: nil

  def user_menu(assigns) do
    ~H"""
    <%= if @current_user.id do %>
      <!-- Profile dropdown -->
      <div class={"flex-shrink-0 relative #{@class}"}>
        <div>
          <button phx-click={toggle_user_menu()} type="button" class="bg-white rounded-full flex focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand-500" id="user-menu" aria-expanded="false" aria-haspopup="true">
            <span class="sr-only">Open user menu</span>
            <img class="h-9 w-9 rounded-full" src={@current_user.avatar} alt="" />
          </button>
        </div>
        <!-- User menu -->
        <div
          id="user-profile"
          phx-click-away={toggle_user_menu()}
          class="hidden origin-top-right absolute z-10 right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 py-1 focus:outline-none divide-y-2 divide-gray-300"
          role="menu"
          aria-orientation="vertical"
          aria-labelledby="user-menu"
        >
          <div>
            <.link href={~p"/logout"} method="delete" class="block py-2 px-4 text-sm text-gray-700 hover:bg-gray-100" role="menuitem">Sign out</.link>
          </div>
          <%= if admin?(@current_user) do %>
            <div>
              <.link href={~p"/admin/dashboard"} class="block py-2 px-4 text-sm text-gray-700 hover:bg-gray-100" role="menuitem">Dashboard</.link>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  def toggle_user_menu do
    JS.toggle(
      to: "#user-profile",
      in:
        {"transition ease-out duration-100", "transform opacity-0 scale-95",
         "transform opacity-100 scale-100"},
      out:
        {"transition ease-in duration-75", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end
end
