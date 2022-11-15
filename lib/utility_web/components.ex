defmodule UtilityWeb.Components do
  @moduledoc false

  use UtilityWeb, :component

  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w[disabled form name value]
  slot :inner_block, required: true
  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "inline-flex items-center px-4 py-2 border border-transparent",
        "text-sm font-medium shadow-sm text-white bg-brand-600 hover:bg-brand-700",
        "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand-500",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :class, :string, default: nil
  attr :active, :string, default: "false"
  attr :group, :string, required: true
  attr :id, :string, required: true
  slot :inner_block, required: true
  def tab(assigns) do
    assigns =
      assign_new(assigns, :active_class, fn %{active: active} ->
        if active == "true", do: "", else: "hidden"
      end)

    ~H"""
    <div data-tab-group={@group} data-tab={"tab-#{@id}-content"} id={"tab-#{@id}-content"} class={"#{@class} #{@active_class}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :group, :string, required: true
  slot :inner_block, required: true
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
      phx-change={JS.dispatch("changeTab", detail: %{active: ["border-brand-300", "text-gray-700", "dark:text-gray-300"]})}>
      <%= render_slot(@inner_block) %>
    </select>
    """
  end

  attr :id, :string, required: true
  attr :target, :string, required: true
  attr :active, :string, default: "false"
  attr :group, :string, required: true
  slot :inner_block, required: true
  def tab_button(assigns) do
    assigns = assign_new(assigns, :active_class, fn %{active: active} ->
      if active == "true" do
        ["border-brand-300 ", "text-gray-700 ", "dark:text-gray-300 "]
      end
    end)

    ~H"""
    <button
      id={"tab-#{@id}-btn"}
      type="button"
      data-tab={@target}
      data-tab-group={@group}
      phx-click={JS.dispatch("changeTab", detail: %{active: ["border-brand-300", "text-gray-700", "dark:text-gray-300"]})}
      class={"ring-brand-900 px-1 py-4 ml-8 text-sm font-medium text-gray-500 whitespace-no-wrap border-b-4 border-transparent leading-5 dark:hover:text-gray-300 hover:text-gray-700 hover:border-brand-500 focus:outline-none dark:focus:text-gray-300 focus:text-gray-700 focus:border-brand-500 #{@active_class}"}
      >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  slot :title_area
  slot :call_to_action, default: []
  slot :navigation, default: []
  slot :content, required: true
  def page_panel(assigns) do
    ~H"""
    <div class="max-w-3xl mt-6 lg:mt-0 mx-auto sm:mx-auto px-0 sm:px-6 lg:max-w-7xl lg:px-8" id={@id}>
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
              <div class="mt-5 flex items-center justify-center sm:mt-0">
                <%= render_slot(@call_to_action) %>
              </div>
            </div>
            <%= if @navigation != [] do %>
            <div class="mt-5">
              <%= render_slot(@navigation) %>
            </div>
            <% end %>

            <%= render_slot(@content) %>
          </div>
        </div>
      </section>
    </div>
    """
  end

  attr :nav_id, :string, required: true
  attr :page_metadata, :any, default: nil
  attr :next, :string, default: "next-page"
  attr :prev, :string, default: "prev-page"
  attr :class, :string, default: ""
  def pagination(assigns) do
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

  @doc """
  Renders an input with label and error messages.
  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.
  ## Examples
      <.input field={{f, :email}} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any
  attr :name, :any
  attr :label, :string, default: nil
  attr :type, :string,
    default: "text",
    values: ~w[checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week]
  attr :value, :any
  attr :field, :any, doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: {f, :email}"
  attr :errors, :list
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :rest, :global, include: ~w[autocomplete disabled form max maxlength min minlength
                                   pattern placeholder readonly required size step]
  slot :inner_block
  def input(%{field: {f, field}} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign_new(:name, fn ->
      name = Phoenix.HTML.Form.input_name(f, field)
      if assigns.multiple, do: name <> "[]", else: name
    end)
    |> assign_new(:id, fn -> Phoenix.HTML.Form.input_id(f, field) end)
    |> assign_new(:value, fn -> Phoenix.HTML.Form.input_value(f, field) end)
    |> assign_new(:errors, fn -> translate_errors(f.errors || [], field) end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns = assign_new(assigns, :checked, fn -> input_equals?(assigns.value, "true") end)

    ~H"""
    <label phx-feedback-for={@name} class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
      <input type="hidden" name={@name} value="false" />
      <input
        type="checkbox"
        id={@id || @name}
        name={@name}
        value="true"
        checked={@checked}
        class="rounded border-zinc-300 text-zinc-900 focus:ring-zinc-900"
        {@rest}
      />
      <%= @label %>
    </label>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-1 block w-full py-2 px-3 border border-gray-300 bg-white rounded-md shadow-sm focus:outline-none focus:ring-zinc-500 focus:border-zinc-500 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt}><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id || @name}
        name={@name}
        class={[
          input_border(@errors),
          "mt-2 block min-h-[6rem] w-full rounded-lg border-zinc-300 py-[7px] px-[11px]",
          "text-zinc-900 focus:border-zinc-400 focus:outline-none focus:ring-4 focus:ring-zinc-800/5 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5"
        ]}
        {@rest}
      >
    <%= @value %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={@value}
        class={[
          input_border(@errors),
          "mt-2 block w-full rounded-lg border-zinc-300 py-[7px] px-[11px]",
          "text-zinc-900 focus:outline-none focus:ring-4 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  defp input_border([] = _errors),
    do: "border-zinc-300 focus:border-zinc-400 focus:ring-zinc-800/5"
  defp input_border([_ | _] = _errors),
    do: "border-rose-400 focus:border-rose-400 focus:ring-rose-400/10"

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true
  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true
  def error(assigns) do
    ~H"""
    <p class="phx-no-feedback:hidden mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  attr :form, :any, required: true
  attr :field, :atom, required: true
  def errors(assigns) do
    ~H"""
    <.error :for={msg <- translate_errors(@form.errors || [], @field)}><%= msg %></.error>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
  defp input_equals?(val1, val2) do
    Phoenix.HTML.html_escape(val1) == Phoenix.HTML.html_escape(val2)
  end
end
