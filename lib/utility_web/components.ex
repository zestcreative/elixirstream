defmodule UtilityWeb.Components do
  @moduledoc false

  use UtilityWeb, :html
  import Utility.Accounts, only: [admin?: 1]

  def show_edit?(%{contributor_id: user_id}, %{id: user_id}), do: true
  def show_edit?(_tip, current_user), do: admin?(current_user)

  def show_approve?(%{approved: true}, _current_user), do: false
  def show_approve?(_tip, current_user), do: admin?(current_user)

  def show_delete?(%{contributor_id: user_id}, %{id: user_id}), do: true
  def show_delete?(_tip, current_user), do: admin?(current_user)

  def tip_card(assigns) do
    assigns = assign_new(assigns, :class, fn -> "" end)

    ~H"""
    <article aria-labelledby={"tip-title-#{@tip.id}"} class={"#{if @tip.approved, do: "border-gray-200 dark:border-transparent", else:
      "border-yellow-500"} border-2 shadow-md dark:bg-gray-900 bg-white overflow-hidden px-4 py-6 sm:p-6 sm:rounded-md #{@class}"}>
      <div>
        <div class="flex space-x-3">
          <div class="flex-shrink-0">
            <img class="h-10 w-10 rounded-full" src={@tip.contributor.avatar} alt="">
          </div>
          <div class="min-w-0 flex-1 text-gray-500 dark:text-gray-400">
            <p class="flex mr-4 items-center justify-between text-sm font-medium dark:text-gray-300 text-gray-900">
              <span><%= @tip.contributor.name %></span>
              <time datetime={DateTime.to_iso8601(@tip.published_at)}><%= @tip.published_at |> DateTime.to_date() |> Date.to_iso8601() %></time>
            </p>
            <p class="inline-flex items-center">
              <UtilityWeb.Components.github_icon class="-ml-0.5 mr-1 h-3 w-3" />
              <a href={"https://github.com/#{@tip.contributor.username}"} target="_blank" rel="nofollow"
              class="hover:underline text-xs"><%= @tip.contributor.username %></a>
            </p>
            <%= if @tip.contributor.twitter do %>
              <p class="ml-3 inline-flex items-center">
                <UtilityWeb.Components.twitter_icon class="-ml-0.5 mr-1 h-3 w-3" />
                <a href={"https://twitter.com/#{@tip.contributor.twitter}"} rel="nofollow" target="_blank"
                class="hover:underline text-xs"><%= @tip.contributor.twitter %></a>
              </p>
            <% end %>
          </div>
        </div>
        <h2 id={"tip-title-#{@tip.id}"} class="mt-4 text-base font-semibold text-gray-900 dark:text-gray-300">
          <.link patch={~p"/tips/#{@tip.id}"}><%= @tip.title %></.link>
        </h2>
      </div>

      <div class="mt-2 text-sm text-gray-700 dark:text-gray-300 space-y-4">
        <%= @tip.description %>
      </div>

      <div class="mt-2 text-sm">
        <%= Phoenix.HTML.raw(Makeup.highlight(@tip.code)) %>
      </div>

      <div class="mt-6 flex justify-between space-x-8">
        <div class="flex space-x-6">
          <span class="inline-flex items-center text-sm">
            <%= cond do %>
              <% @current_user.id && @current_user.id != @tip.contributor_id && @tip.id not in @upvoted_tip_ids -> %>
                <button phx-click="upvote-tip" phx-value-tip-id={@tip.id} class="focus:ring-0 focus:outline-none inline-flex space-x-2 text-gray-400 hover:text-green-500">
                  <UtilityWeb.Components.thumbs_up_icon class="h-5 w-5" />
                  <span class="font-medium dark:text-gray-300 text-gray-900"><%= @tip.upvote_count + @tip.twitter_like_count %></span>
                  <span class="sr-only">upvotes</span>
                </button>
              <% @current_user.id && @current_user.id != @tip.contributor_id && @tip.id in @upvoted_tip_ids -> %>
                <button phx-click="downvote-tip" phx-value-tip-id={@tip.id} class="focus:ring-0 focus:outline-none inline-flex space-x-2 text-green-400 hover:text-red-500">
                  <UtilityWeb.Components.thumbs_up_icon class="h-5 w-5 transform duration-300 hover:rotate-180" />
                  <span class="font-medium dark:text-gray-300 text-gray-900"><%= @tip.upvote_count + @tip.twitter_like_count %></span>
                  <span class="sr-only">upvotes</span>
                </button>
              <% true -> %>
                <div class="inline-flex space-x-2 text-gray-400">
                  <UtilityWeb.Components.thumbs_up_icon class="h-5 w-5" />
                  <span class="font-medium dark:text-gray-300 text-gray-900"><%= @tip.upvote_count + @tip.twitter_like_count %></span>
                  <span class="sr-only">upvotes</span>
                </div>
            <% end %>
          </span>
        </div>
        <div class="flex text-sm">
          <%= if show_edit?(@tip, @current_user) do %>
            <.link patch={~p"/tips/#{@tip.id}/edit"} class="ml-2 inline-flex space-x-2 text-gray-400 hover:text-gray-500">
              <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
              <span class="font-medium dark:text-gray-300 text-gray-900">Edit</span>
            </.link>
          <% end %>

          <%= if show_delete?(@tip, @current_user) do %>
            <span class="ml-2 inline-flex items-center text-sm">
              <button phx-click="delete-tip" phx-value-tip-id={@tip.id} class="inline-flex space-x-2 text-red-400 hover:text-red-500">
                <!-- Heroicon name: outline/trash -->
                <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
                <span class="font-medium text-red-900">Delete</span>
              </button>
            </span>
          <% end %>

          <%= if show_approve?(@tip, @current_user) do %>
            <span class="ml-2 inline-flex items-center text-sm">
              <button phx-click="approve-tip" phx-value-tip-id={@tip.id} class="inline-flex space-x-2 text-green-400 hover:text-green-500">
                <!-- Heroicon name: outline/badge-check -->
                <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
                </svg>
                <span class="font-medium text-green-900">Approve</span>
              </button>
            </span>
          <% end %>
        </div>

      </div>
    </article>
    """
  end

  def tab_active, do: ["border-brand-300", "text-gray-700", "dark:text-gray-300"]
  def tab_active_str, do: Enum.join(tab_active(), " ")

  def tab(assigns) do
    assigns = assigns
      |> assign_new(:class, fn -> nil end)
      |> assign_new(:active, fn -> false end)
      |> assign_new(:active_class, fn %{active: active} ->
        if active, do: "", else: "hidden"
      end)

    ~H"""
    <div data-tab-group={@group} data-tab={"tab-#{@id}-content"} id={"tab-#{@id}-content"} class={"#{@class} #{@active_class}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def tab_select(assigns) do
    ~H"""
    <label class="block text-sm font-medium leading-5 dark:text-gray-300 text-gray-700" for={"#{@group}-select"}>
      <%= @title %>
    </label>
    <select
      class="mt-1 rounded-md focus:ring focus:ring-blue-500 focus:ring-opacity-50 focus:border-accent-500 block w-full pl-3 pr-10 py-2 text-base leading-6 dark:border-gray-700 border-gray-300 sm:text-sm sm:leading-5 transition ease-in-out duration-150"
      data-tab-group={@group}
      aria-label={@title}
      id={"#{@group}-select"}
      phx-change={JS.dispatch("changeTab", detail: %{active: tab_active()})}>
      <%= render_slot(@inner_block) %>
    </select>
    """
  end

  def tab_button(assigns) do
    assigns = assign_new(assigns, :active, fn -> false end)
    assigns = assign_new(assigns, :active, fn -> false end)

    ~H"""
    <button
      id={"tab-#{@id}-btn"}
      type="button"
      data-tab={@target}
      data-tab-group={@group}
      phx-click={JS.dispatch("changeTab", detail: %{active: tab_active()})}
      class={"ring-brand-900 px-1 py-4 ml-8 text-sm font-medium text-gray-500 whitespace-no-wrap border-b-4 border-transparent leading-5 dark:hover:text-gray-300 hover:text-gray-700 hover:border-brand-500 focus:outline-none dark:focus:text-gray-300 focus:text-gray-700 focus:border-brand-500 #{if @active == "true", do: tab_active_str()}"}
      >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def page_panel(assigns) do
    assigns = assign_new(assigns, :title_area, fn -> [] end)
    ~H"""
    <div class="max-w-3xl mt-6 lg:mt-0 mx-auto px-4 sm:px-6 lg:max-w-7xl lg:px-8" id={@id}>
      <section aria-labelledby={"#{@id}-title"}>
        <div class="rounded-lg dark:bg-gray-900 bg-white overflow-hidden shadow">
          <h2 class="sr-only" id={"#{@id}-title"}><%= @title %></h2>
          <div class="dark:bg-gray-800 bg-white p-6">
            <div class="sm:flex sm:items-center sm:justify-between">
              <div class="sm:flex sm:space-x-5 items-center">
                <%= render_slot(@title_area) %>
                <div class="mt-4 text-center sm:mt-0 sm:pt-1 sm:text-left">
                  <p class="text-xl font-bold dark:text-gray-100 text-gray-900 sm:text-2xl">
                    <%= @title %>
                  </p>
                </div>
              </div>
              <div class="mt-5 flex justify-center sm:mt-0">
                <%= render_slot(@call_to_action) %>
              </div>
            </div>

            <%= render_slot(@content) %>
          </div>
        </div>
      </section>
    </div>
    """
  end

  def gear_icon(assigns) do
    assigns = assigns |> assign_new(:class, fn -> nil end)
    ~H"""
    <svg
      class={@class}
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
      />
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
      />
    </svg>
    """
  end

  def diff_icon(assigns) do
    assigns = assigns |> assign_new(:class, fn -> nil end)

    ~H"""
    <svg
      class={@class}
      stroke="none"
      fill="currentColor"
      viewBox="0 0 896 1024"
    >
      <path d="M448 256H320v128H192v128h128v128h128V512h128V384H448V256zM192 896h384V768H192V896zM640 0H128v64h480l224 224v608h64V256L640 0zM0 128v896h768V320L576 128H0zM704 960H64V192h480l160 160V960z" />
    </svg>
    """
  end

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
      |> assign_new(:next, fn -> "next-page" end)
      |> assign_new(:prev, fn -> "prev-page" end)
      |> assign_new(:class, fn -> "" end)

    ~H"""
    <%= if @page_metadata && (@page_metadata.before || @page_metadata.after) do %>
      <nav id={@nav_id} aria-label="Pagination" class={"px-2 flex-1 flex justify-between sm:justify-end #{@class}"}>
        <button disabled={!@page_metadata.before} phx-click={@prev} class="relative inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 text-sm font-medium select-none rounded-md dark:bg-gray-700 bg-white disabled:pointer-events-none disabled:opacity-50 hover:bg-gray-50">
          <!-- Heroicon name: chevron-left -->
          <svg class="text-gray-400 h-5 w-5 mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
          <span class="font-medium dark:text-white text-gray-900">Previous Page</span>
        </button>
        <button disabled={!@page_metadata.after} phx-click={@next} class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 text-sm font-medium select-none rounded-md dark:bg-gray-700 bg-white disabled:pointer-events-none disabled:opacity-50 hover:bg-gray-50">
          <span class="font-medium mr-1 dark:text-white text-gray-900">Next Page</span>
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
