defmodule UtilityWeb.Components do
  @moduledoc false
  use Phoenix.Component

  def twitter_icon(assigns) do
    assigns = assigns |> assign_new(:class, fn -> nil end)

    ~H"""
    <svg class={@class} fill="currentColor" alt="Twitter logo" viewBox="328 355 335 276" xmlns="http://www.w3.org/2000/svg">
      <path d="M 630, 425 A 195, 195 0 0 1 331, 600 A 142, 142 0 0 0 428, 570 A  70,  70 0 0 1 370, 523 A  70,  70 0 0 0 401, 521 A  70,  70 0 0 1 344, 455 A  70,  70 0 0 0 372, 460 A  70,  70 0 0 1 354, 370 A 195, 195 0 0 0 495, 442 A  67,  67 0 0 1 611, 380 A 117, 117 0 0 0 654, 363 A  65,  65 0 0 1 623, 401 A 117, 117 0 0 0 662, 390 A  65,  65 0 0 1 630, 425 Z" />
    </svg>
    """
  end
  def github_icon(assigns) do
    assigns = assigns |> assign_new(:class, fn -> nil end)

    ~H"""
    <svg class={@class} fill="currentcolor" alt="GitHub logo" role="img" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/>
    </svg>
    """
  end

  def thumbs_up_icon(assigns) do
    assigns = assigns |> assign_new(:class, fn -> nil end)
    ~H"""
    <!-- Heroicon name: solid/thumb-up -->
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
      <path d="M2 10.5a1.5 1.5 0 113 0v6a1.5 1.5 0 01-3 0v-6zM6 10.333v5.43a2 2 0 001.106 1.79l.05.025A4 4 0 008.943 18h5.416a2 2 0 001.962-1.608l1.2-6A2 2 0 0015.56 8H12V4a2 2 0 00-2-2 1 1 0 00-1 1v.667a4 4 0 01-.8 2.4L6.8 7.933a4 4 0 00-.8 2.4z" />
    </svg>
    """
  end


  def search_icon(assigns) do
    assigns = assigns |> assign_new(:class, fn -> nil end)

    ~H"""
    <!-- Heroicon name: solid/search -->
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
      <path fill-rule="evenodd" d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" clip-rule="evenodd" />
    </svg>
    """
  end

  def close_icon(assigns) do
    assigns = assigns |> assign_new(:class, fn -> nil end)

    ~H"""
    <span class="sr-only">Close</span>
    <!-- Heroicon name: outline/x -->
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
    </svg>
    """
  end

  def pagination(assigns) do
    assigns =
      assigns
      |> assign_new(:page_metadata, fn -> nil end)
      |> assign_new(:next, "next-page")
      |> assign_new(:prev, "prev-page")

    ~H"""
    <%= if @page_metadata && (@page_metadata.before || @page_metadata.after) do %>
      <nav id={@nav_id} aria-label="Pagination" class="px-2 flex-1 flex justify-between sm:justify-end">
        <button phx-click={@prev} class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md bg-white hover:bg-gray-50">
          <!-- Heroicon name: chevron-left -->
          <svg class="text-gray-400 h-5 w-5 mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
          <span class="font-medium text-gray-900">Previous Page</span>
        </button>
        <button phx-click={@next} class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md bg-white hover:bg-gray-50">
          <span class="font-medium mr-1 text-gray-900">Next Page</span>
          <!-- Heroicon name: chevron-right -->
          <svg class="text-gray-400 h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </button>
      </nav>
    <% end %>
    """
  end
end
