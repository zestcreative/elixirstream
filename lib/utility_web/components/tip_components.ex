defmodule UtilityWeb.Components.Tip do
  @moduledoc false
  use UtilityWeb, :component
  import UtilityWeb.Components
  import Utility.Accounts, only: [admin?: 1]

  def show_approve?(%{approved: true}, _current_user), do: false
  def show_approve?(_tip, current_user), do: admin?(current_user)

  def show_delete?(%{contributor_id: user_id}, %{id: user_id}), do: true
  def show_delete?(_tip, current_user), do: admin?(current_user)

  def max_characters, do: UtilityWeb.TipLive.character_limit()

  @warning_threshold_below_max 20
  @warning_threshold_below_min 20
  def color_for_bar(count, max_count)
      when count <= @warning_threshold_below_min
      when count > max_count do
    {"bg-red-200 dark:bg-red-800", "bg-red-500"}
  end

  def color_for_bar(count, max_count) do
    if count > max_count - @warning_threshold_below_max do
      {"bg-yellow-200 dark:bg-yellow-800", "bg-yellow-500"}
    else
      {"bg-brand-200 dark:bg-brand-700", "bg-brand-500"}
    end
  end

  attr :user, Utility.Accounts.User, required: true

  def contributor(assigns) do
    ~H"""
    <div class="flex space-x-3">
      <div class="flex-shrink-0">
        <img class="h-10 w-10 rounded-full" src={@user.avatar} alt="" />
      </div>
      <div class="min-w-0 flex-1 text-gray-500 dark:text-gray-400">
        <p class="text-sm font-medium dark:text-gray-300 text-gray-900">
          <span>
            {@user.name}
          </span>

          <p class="inline-flex items-center">
            <Icon.github class="-ml-0.5 mr-1 h-3 w-3" />
            <a href={"https://github.com/#{@user.username}"} target="_blank" rel="nofollow" class="hover:underline text-xs text-gray-500">
              {@user.username}
            </a>
          </p>

          <%= if @user.twitter do %>
            <p class="ml-3 inline-flex items-center">
              <Icon.twitter class="-ml-0.5 mr-1 h-3 w-3" />
              <a href={"https://twitter.com/#{@user.twitter}"} rel="nofollow" target="_blank" class="hover:underline text-xs text-gray-500">
                {@user.twitter}
              </a>
            </p>
          <% end %>
        </p>
        <p class="text-sm text-gray-500">
          <div class="sm:col-span-3"></div>
        </p>
      </div>
    </div>
    """
  end

  attr :changeset, Ecto.Changeset, required: true
  attr :phx_change, :string, required: true
  attr :action, :atom, required: true, values: [:edit, :new]
  attr :phx_submit, :string, required: true
  attr :tip_form, UtilityWeb.TipLive, required: true
  attr :tip, Utility.TipCatalog.Tip, required: true
  attr :character_percent, :float, required: true
  attr :upvoted_tip_ids, :list, default: []
  attr :character_count, :integer, required: true
  attr :current_user, Utility.Accounts.User, required: true

  def edit(assigns) do
    ~H"""
    <.form id="tipform" for={@form} phx-change={@phx_change} phx-submit={@phx_submit}>
      <.contributor user={@tip_form.contributor} />

      <div class="mt-2 text-sm dark:text-gray-300 text-gray-700 space-y-4">
        <div class="mt-1">
          <.label for={@form[:title]} class="block text-sm font-medium dark:text-gray-300 text-gray-700">Title</.label>
          <div class="mt-1">
            <.input type="text" field={@form[:title]} class="shadow-sm focus:ring-brand-500 focus:border-brand-500 block w-full sm:text-sm dark:border-gray-700 border-gray-300 rounded-md" />
            <Components.errors form={@form} field={:title} />
          </div>
        </div>

        <div class="mt-1">
          <.label for={@form[:description]} class="block text-sm font-medium dark:text-gray-300 text-gray-700">Description</.label>
          <div class="mt-1">
            <.input type="textarea" field={@form[:description]} class="shadow-sm focus:ring-brand-500 focus:border-brand-500 block w-full sm:text-sm dark:border-gray-700 border-gray-300 rounded-md" />
            <Components.errors form={@form} field={:description} />
          </div>

          <div class="relative pt-1">
            <% {track_color, bar_color} = color_for_bar(@character_count, max_characters()) %>
            <div class={"overflow-hidden h-4 mb-4 text-xs flex rounded #{track_color}"}>
              <div style={"width: #{@character_percent}%"} class={"shadow-none flex flex-col whitespace-nowrap text-white justify-center #{bar_color}"}>
                <span class="text-xs pl-1">{@character_count} / {max_characters()}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-1">
        <.label for={@form[:code]} class="block text-sm font-medium dark:text-gray-300 text-gray-700">Code</.label>
        <div class="w-full" id="code-editor-content" class="mt-1" phx-hook="CodeMirror" data-mount-replace-selector="#code-editor-mount-replace" data-mount-selector="#code-editor-container">
          <div id="code-editor-container" phx-update="ignore">
            <.input type="textarea" field={@form[:code]} class="font-mono shadow-sm focus:ring-brand-500 focus:border-brand-500 block w-full sm:text-sm dark:border-gray-700 border-gray-300 rounded-md" rows={12} id="code-editor-mount-replace" />
          </div>
          <span class="text-gray-500 text-xs"><kbd>ESC</kbd> toggles trapping tab</span>
          <Components.errors form={@form} field={:code} />
        </div>
      </div>

      <div class="mt-2">
        <Components.button type="button" phx-click="preview">Preview</Components.button>
        <img phx-hook="PreviewImage" id="preview-image" class="mt-2 max-h-80" />
      </div>
      <div class="mt-3 text-center sm:ml-4 sm:text-left"></div>
    </.form>
    """
  end

  attr :current_user, Utility.Accounts.User, required: true
  attr :tip, Utility.TipCatalog.Tip, required: true
  attr :upvoted_tip_ids, :list, required: true

  def upvote(%{current_user: %{id: user_id}, tip: %{contributor_id: contributor_id}} = assigns)
      when user_id != contributor_id do
    if assigns.tip.id in assigns.upvoted_tip_ids do
      ~H"""
      <button phx-click="downvote-tip" phx-value-tip-id={@tip.id} class="focus:ring-0 focus:outline-none inline-flex space-x-2 text-green-400 hover:text-red-500">
        <Icon.thumbs_up class="h-5 w-5 transform duration-300 hover:rotate-180" />
        <span class="font-medium text-gray-900">
          {@tip.upvote_count + @tip.twitter_like_count}
        </span>
        <span class="sr-only">upvotes</span>
      </button>
      """
    else
      ~H"""
      <button phx-click="upvote-tip" phx-value-tip-id={@tip.id} class="focus:ring-0 focus:outline-none inline-flex space-x-2 text-gray-400 hover:text-green-500">
        <Icon.thumbs_up class="h-5 w-5" />
        <span class="font-medium text-gray-900">
          {@tip.upvote_count + @tip.twitter_like_count}
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
        {@tip.upvote_count + @tip.twitter_like_count}
      </span>
      <span class="sr-only">upvotes</span>
    </div>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :phx_change, :string, required: true
  attr :meta, Quarto.Config, default: nil
  attr :id, :string, required: true

  def search(assigns) do
    ~H"""
    <label for="search" class="sr-only">Search Tips</label>
    <div class="mt-1 flex justify-center rounded-md">
      <Components.button phx-click="prev-page" class={"#{if !@meta.before, do: "invisible"} relative -ml-px inline-flex items-center space-x-2 rounded-l-md px-4 py-2 text-sm shadow-sm font-medium"}>
        <Icon.chevron_left class="h-5 w-5 mr-1" /> Previous
      </Components.button>

      <div class="relative flex flex-grow items-stretch shadow-sm focus-within:z-10">
        <div class="pointer-events-none absolute inset-y-0 left-0 pl-3 flex items-center">
          <Icon.search class="h-5 w-5 text-gray-400" />
        </div>

        <.form as={:search} for={@form} phx-submit="" phx-change={@phx_change} id={"#{@id}-form"}>
          <.input type="search" field={@form[:q]} phx-debounce="250" class="block w-full rounded-none border-brand-500 pl-10 focus:border-brand-700 focus:ring-brand-500 sm:text-sm" maxlength={75} phx-hook="RegisterSlash" placeholder="Search tips" id={@id} />
        </.form>
      </div>
      <Components.button phx-click="next-page" class={"#{if !@meta.after, do: "invisible"} relative -ml-px inline-flex items-center space-x-2 rounded-r-md px-4 py-2 text-sm font-medium shadow-sm"}>
        Next <Icon.chevron_right class="h-5 w-5" />
      </Components.button>
    </div>
    """
  end

  attr :tip, Utility.TipCatalog.Tip, required: true
  attr :current_user, Utility.Accounts.User, required: true
  attr :editable?, :boolean, default: false
  attr :class, :string, default: nil
  attr :upvoted_tip_ids, :list, default: []

  def show(assigns) do
    ~H"""
    <li class="xs:px-0 sm:px-6 py-12 sm:px-0">
      <article aria-labelledby={"tip-title-#{@tip.id}"} class={"#{if !@tip.approved, do: "border-2 border-dashed p-3 border-yellow-500"} overflow-hidden"}>
        <div>
          <div class="flex space-x-3">
            <div class="flex-shrink-0">
              <img class="h-10 w-10 rounded-full" src={@tip.contributor.avatar} alt="" />
            </div>
            <div class="min-w-0 flex-1 text-gray-500 dark:text-gray-400">
              <p class="flex mr-4 items-center justify-between text-sm font-medium dark:text-gray-300 text-gray-900">
                <span>{@tip.contributor.name}</span>
                <time datetime={DateTime.to_iso8601(@tip.published_at)}>{@tip.published_at |> DateTime.to_date() |> Date.to_iso8601()}</time>
              </p>
              <p class="inline-flex items-center">
                <Icon.github class="-ml-0.5 mr-1 h-3 w-3" />
                <a href={"https://github.com/#{@tip.contributor.username}"} target="_blank" rel="nofollow" class="hover:underline text-xs">{@tip.contributor.username}</a>
              </p>
              <%= if @tip.contributor.twitter do %>
                <p class="ml-3 inline-flex items-center">
                  <Icon.twitter class="-ml-0.5 mr-1 h-3 w-3" />
                  <a href={"https://twitter.com/#{@tip.contributor.twitter}"} rel="nofollow" target="_blank" class="hover:underline text-xs">{@tip.contributor.twitter}</a>
                </p>
              <% end %>
            </div>
          </div>
          <h2 id={"tip-title-#{@tip.id}"} class="mt-4 text-xl font-semibold text-gray-900 dark:text-gray-300">
            <.link patch={~p"/tips/#{@tip.id}"}>{@tip.title}</.link>
          </h2>
        </div>

        <div class="mt-2 text-lg text-gray-700 dark:text-gray-300 space-y-4">
          {@tip.description}
        </div>

        <div class="mt-2 text-base">
          {Phoenix.HTML.raw(Makeup.highlight(@tip.code))}
        </div>

        <div class="mt-6 flex justify-between space-x-8">
          <div class="flex space-x-6">
            <span class="inline-flex items-center text-sm">
              <%= cond do %>
                <% @current_user.id && @current_user.id != @tip.contributor_id && @tip.id not in @upvoted_tip_ids -> %>
                  <button phx-click="upvote-tip" phx-value-tip-id={@tip.id} class="focus:ring-0 focus:outline-none inline-flex space-x-2 text-gray-400 hover:text-green-500">
                    <Icon.thumbs_up class="h-5 w-5" />
                    <span class="font-medium dark:text-gray-300 text-gray-900">{@tip.upvote_count + @tip.twitter_like_count}</span>
                    <span class="sr-only">upvotes</span>
                  </button>
                <% @current_user.id && @current_user.id != @tip.contributor_id && @tip.id in @upvoted_tip_ids -> %>
                  <button phx-click="downvote-tip" phx-value-tip-id={@tip.id} class="focus:ring-0 focus:outline-none inline-flex space-x-2 text-green-400 hover:text-red-500">
                    <Icon.thumbs_up class="h-5 w-5 transform duration-300 hover:rotate-180" />
                    <span class="font-medium dark:text-gray-300 text-gray-900">{@tip.upvote_count + @tip.twitter_like_count}</span>
                    <span class="sr-only">upvotes</span>
                  </button>
                <% true -> %>
                  <div class="inline-flex space-x-2 text-gray-400">
                    <Icon.thumbs_up class="h-5 w-5" />
                    <span class="font-medium dark:text-gray-300 text-gray-900">{@tip.upvote_count + @tip.twitter_like_count}</span>
                    <span class="sr-only">upvotes</span>
                  </div>
              <% end %>
            </span>
          </div>
          <div class="flex text-sm">
            <%= if @editable? do %>
              <.link patch={~p"/tips/#{@tip.id}/edit"} class="ml-2 inline-flex space-x-2 text-gray-400 hover:text-gray-500">
                <Icon.pencil class="h-5 w-5" />
                <span class="font-medium dark:text-gray-300 text-gray-900">Edit</span>
              </.link>
            <% end %>

            <%= if show_delete?(@tip, @current_user) do %>
              <span class="ml-2 inline-flex items-center text-sm">
                <button phx-click="delete-tip" phx-value-tip-id={@tip.id} class="inline-flex space-x-2 text-red-400 hover:text-red-500">
                  <Icon.trash class="h-5 w-5" />
                  <span class="font-medium text-red-900">Delete</span>
                </button>
              </span>
            <% end %>

            <%= if show_approve?(@tip, @current_user) do %>
              <span class="ml-2 inline-flex items-center text-sm">
                <button phx-click="approve-tip" phx-value-tip-id={@tip.id} class="inline-flex space-x-2 text-green-400 hover:text-green-500">
                  <Icon.badge_check class="h-5 w-5" />
                  <span class="font-medium text-green-900">Approve</span>
                </button>
              </span>
            <% end %>
          </div>
        </div>
      </article>
    </li>
    """
  end
end
