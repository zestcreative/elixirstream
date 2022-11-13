defmodule UtilityWeb.Components.Tip do
  @moduledoc false
  use UtilityWeb, :component
  import Utility.Accounts, only: [admin?: 1]
  import Phoenix.HTML.Form, only: [label: 4, text_input: 3, textarea: 3, submit: 2, date_input: 3]

  def show_edit?(%{contributor_id: user_id}, %{id: user_id}), do: true
  def show_edit?(_tip, current_user), do: admin?(current_user)

  def show_approve?(%{approved: true}, _current_user), do: false
  def show_approve?(_tip, current_user), do: admin?(current_user)

  def show_delete?(%{contributor_id: user_id}, %{id: user_id}), do: true
  def show_delete?(_tip, current_user), do: admin?(current_user)

  def max_characters, do: UtilityWeb.TipLive.character_limit()

  @warning_threshold_below_max 20
  def color_for_bar(count, max_count) when count > max_count do
    {"bg-red-200", "bg-red-500"}
  end

  def color_for_bar(count, max_count) do
    if count > max_count - @warning_threshold_below_max do
      {"bg-yellow-200", "bg-yellow-500"}
    else
      {"bg-brand-200", "bg-brand-500"}
    end
  end

  attr :changeset, Ecto.Changeset, required: true
  attr :phx_change, :string, required: true
  attr :action, :atom, required: true, values: [:edit, :new]
  attr :phx_submit, :string, required: true
  attr :tip_form, UtilityWeb.TipLive, required: true
  attr :tip, Utility.TipCatalog.Tip, required: true
  attr :character_percent, :float, required: true
  attr :character_count, :integer, required: true
  def tip_form(assigns) do
    ~H"""
    <.form let={f} for={@changeset} phx-change={@phx_change} phx-submit={@phx_submit}>
      <%# who posting %>
      <div>
        <div class="flex space-x-3">
          <div class="flex-shrink-0">
            <img class="h-10 w-10 rounded-full" src={@tip_form.contributor.avatar} alt="">
          </div>
          <div class="min-w-0 flex-1">
            <p class="text-sm font-medium text-gray-900">
              <span>
                <%= @tip_form.contributor.name %>
              </span>

              <p class="inline-flex items-center">
                <Icon.github class="-ml-0.5 mr-1 h-3 w-3" />
                <a href={"https://github.com/#{@tip_form.contributor.username}"} target="_blank" rel="nofollow"
                  class="hover:underline text-xs text-gray-500">
                  <%= @tip_form.contributor.username %>
                </a>
              </p>

              <%= if @tip_form.contributor.twitter do %>
                <p class="ml-3 inline-flex items-center">
                  <Icon.twitter class="-ml-0.5 mr-1 h-3 w-3" />
                  <a href={"https://twitter.com/#{@tip_form.contributor.twitter}"} rel="nofollow" target="_blank"
                    class="hover:underline text-xs text-gray-500">
                    <%= @tip_form.contributor.twitter %>
                  </a>
                </p>
              <% end %>
            </p>
            <p class="text-sm text-gray-500">
              <div class="sm:col-span-3"></div>
            </p>
          </div>
        </div>
      </div>

      <%# form %>
      <div class="mt-2 text-sm text-gray-700 space-y-4">
        <div class="mt-1">
          <%= label f, :title, "Title" , class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= text_input f, :title, class: "shadow-sm focus:ring-brand-500 focus:border-brand-500 block w-full sm:text-sm border-gray-300 rounded-md" %>
            <Components.errors form={f} field={:title} />
          </div>
        </div>
        <div class="mt-1">
          <%= label f, :description, "Description", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= textarea f, :description, class: "shadow-sm focus:ring-brand-500 focus:border-brand-500 block w-full sm:text-sm border-gray-300 rounded-md" %>
            <Components.errors form={f} field={:description} />
          </div>

          <div class="relative pt-1">
            <% {track_color, bar_color} = color_for_bar(@character_count, max_characters()) %>
            <div class={"overflow-hidden h-4 mb-4 text-xs flex rounded #{track_color}"}>
              <div style={"width: #{@character_percent}%"} class={"shadow-none flex flex-col whitespace-nowrap text-white justify-center #{bar_color}"}>
                <span class="text-xs pl-1">
                  <%= @character_count %> / <%= max_characters() %>
                </span>
              </div>

              <div class="sm:flex sm:items-start">
                <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                  <h3 class="text-lg leading-6 font-medium text-gray-900" id="modal-headline">
                    Preview
                  </h3>
                  <div class="mt-2">
                    <p class="text-sm text-gray-500">
                      <img src="src" class="object-contain h-1/2-screen" />
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-6 flex justify-between space-x-8">
        <div class="flex space-x-6">
        </div>
        <div class="flex text-sm">
          <%# Edit Form %>
          <%= if @action == :edit do %>
            <%= if @tip.twitter_status_id do %>
              <span class="text-xs text-gray-600">
                Tweet is already published. Updating will not update the tweet
              </span>
            <% end %>

            <%= submit class: "ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-brand-600 hover:bg-brand-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand-500" do %>
              <Icon.loading class="animate-spin hidden -ml-1 mr-3 h-5 w-5 text-white" />
              Update
            <% end %>
          <% else %>
            <div class="inline-flex items-center text-sm">
              <%= label f, :published_at, "Publish On", class: "block text-sm font-medium text-gray-700" %>
              <div class="ml-2">
                <%= date_input f, :published_at,
                    min: Date.to_iso8601(Date.utc_today()),
                    class: "shadow-sm focus:ring-brand-500 focus:border-brand-500 block w-full sm:text-sm border-gray-300 rounded-md" %>
                <Components.errors form={f} field={:published_at} />
              </div>
            </div>
            <h2 id={"tip-title-#{@tip.id}"} class="mt-4 text-base font-semibold text-gray-900">
              <.link patch={~p"/tips/#{@tip.id}"}><%= @tip.title %></.link>
            </h2>
            <div class="mt-2 text-sm text-gray-700 space-y-4">
              <%= @tip.description %>
            </div>
            <div class="mt-2 text-sm">
              <%= raw(Makeup.highlight(@tip.code)) %>
            </div>
          <% end %>

          <div class="mt-6 flex justify-between space-x-8">
            <div class="flex space-x-6">
              <span class="inline-flex items-center text-sm">
                <.upvote current_user={@current_user} tip={@tip} upvoted_tip_ids={@upvoted_tip_ids} />
              </span>
            </div>

            <div class="flex text-sm">
              <%= if show_edit?(@tip, @current_user) do %>
                <.link patch={~p"/tips/#{@tip.id}"} class="ml-2 inline-flex space-x-2 text-gray-400 hover:text-gray-500">
                  <Icon.pencil class="h-5 w-5" />
                  <span class="font-medium text-gray-900">Edit</span>
                </.link>
                <% end %>
            </div>
          </div>
        </div>
      </div>
    </.form>
    """
  end

  attr :current_user, Utility.Accounts.User, required: true
  attr :tip, Utility.TipCatalog.Tip, required: true
  attr :upvoted_tip_ids, :list, required: true
  def upvote(%{current_user: %{id: user_id}, tip: %{contributor_id: contributor_id}} = assigns)
      when user_id != contributor_id do
    if assigns.tip_id in assigns.upvoted_tip_ids do
      ~H"""
      <button phx-click="downvote-tip" phx-value-tip-id={@tip.id}
        class="focus:ring-0 focus:outline-none inline-flex space-x-2 text-green-400 hover:text-red-500">
        <Icon.thumbs_up class="h-5 w-5 transform duration-300 hover:rotate-180" />
        <span class="font-medium text-gray-900">
          <%= @tip.upvote_count + @tip.twitter_like_count %>
        </span>
        <span class="sr-only">upvotes</span>
      </button>
      """
    else
      ~H"""
      <button phx-click="upvote-tip" phx-value-tip-id={@tip.id}
        class="focus:ring-0 focus:outline-none inline-flex space-x-2 text-gray-400 hover:text-green-500">
        <Icon.thumbs_up class="h-5 w-5" />
        <span class="font-medium text-gray-900">
          <%= @tip.upvote_count + @tip.twitter_like_count %>
        </span>
        <span class="sr-only">upvotes</span>
      </button>
      """
    end
  end

  def upvote(assigns) do
    ~H"""
    <div class="inline-flex space-x-2 text-gray-400">
      <Icon.thumbs_up class="h-5 w-5" />
      <span class="font-medium text-gray-900">
        <%= @tip.upvote_count + @tip.twitter_like_count %>
      </span>
      <span class="sr-only">upvotes</span>
    </div>
    """
  end

  attr :changeset, Ecto.Changeset, required: true
  attr :phx_change, :string, required: true
  attr :id, :string, required: true
  def search(assigns) do
    ~H"""
    <label for="search" class="sr-only">Search</label>
    <div class="relative">
      <div class="pointer-events-none absolute inset-y-0 left-0 pl-3 flex items-center">
        <Icon.search class="h-5 w-5 text-gray-400" />
      </div>

      <.form let={f} as={:search} for={@changeset} phx-change={@phx_change} id={"#{@id}-form"} onsubmit="return false;">
        <%= Phoenix.HTML.Form.search_input f, :q, phx_debounce: "250",
          class: "block w-full bg-white border border-gray-300 rounded-md py-2 pl-10 pr-3 text-sm placeholder-gray-500 focus:outline-none focus:text-gray-900 focus:placeholder-gray-400 focus:ring-1 focus:ring-brand-500 focus:border-brand-500 sm:text-sm",
          maxlength: "75",
          phx_hook: "RegisterSlash",
          placeholder: "Search tips",
          id: @id %>
      </.form>
    </div>
    """
  end

  attr :tip, Utility.TipCatalog.Tip, required: true
  attr :current_user, Utility.Accounts.User, required: true
  attr :class, :string, default: nil
  def card(assigns) do
    ~H"""
    <article aria-labelledby={"tip-title-#{@tip.id}"} class={"#{if @tip.approved, do: "border-gray-200 dark:border-transparent", else: "border-yellow-500"} border-2 shadow-md dark:bg-gray-900 bg-white overflow-hidden px-4 py-6 sm:p-6 sm:rounded-md #{@class}"}>
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
              <Icon.github class="-ml-0.5 mr-1 h-3 w-3" />
              <a href={"https://github.com/#{@tip.contributor.username}"} target="_blank" rel="nofollow"
              class="hover:underline text-xs"><%= @tip.contributor.username %></a>
            </p>
            <%= if @tip.contributor.twitter do %>
              <p class="ml-3 inline-flex items-center">
                <Icon.twitter class="-ml-0.5 mr-1 h-3 w-3" />
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
                  <Icon.thumbs_up class="h-5 w-5" />
                  <span class="font-medium dark:text-gray-300 text-gray-900"><%= @tip.upvote_count + @tip.twitter_like_count %></span>
                  <span class="sr-only">upvotes</span>
                </button>
              <% @current_user.id && @current_user.id != @tip.contributor_id && @tip.id in @upvoted_tip_ids -> %>
                <button phx-click="downvote-tip" phx-value-tip-id={@tip.id} class="focus:ring-0 focus:outline-none inline-flex space-x-2 text-green-400 hover:text-red-500">
                  <Icon.thumbs_up class="h-5 w-5 transform duration-300 hover:rotate-180" />
                  <span class="font-medium dark:text-gray-300 text-gray-900"><%= @tip.upvote_count + @tip.twitter_like_count %></span>
                  <span class="sr-only">upvotes</span>
                </button>
              <% true -> %>
                <div class="inline-flex space-x-2 text-gray-400">
                  <Icon.thumbs_up class="h-5 w-5" />
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

end
