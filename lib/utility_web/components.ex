defmodule UtilityWeb.Components do
  @moduledoc false

  use UtilityWeb, :component

  attr :href, :string, required: true
  attr :rest, :global, include: ~w(download hreflang referrerpolicy target type)
  slot :inner_block, required: true

  def outbound_link(assigns) do
    ~H"""
    <.link rel="nofollow noopener" href={@href} {@rest}>{render_slot(@inner_block)}</.link>
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
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :id, :string, required: true
  attr :target, :string, required: true
  attr :active, :string, default: "false"
  attr :group, :string, required: true
  slot :inner_block, required: true

  def tab_button(assigns) do
    assigns =
      assign_new(assigns, :active_class, fn %{active: active} ->
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
      class={"ring-brand-900 px-1 py-4 ml-8 text-sm font-medium text-gray-400 whitespace-no-wrap border-b-4 border-transparent leading-5 dark:hover:text-gray-300 hover:text-gray-700 hover:border-brand-500 focus:outline-none dark:focus:text-gray-300 focus:text-gray-700 focus:border-brand-500 #{@active_class}"}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  slot :title_area
  slot :call_to_action
  slot :navigation
  slot :titlebar
  slot :description
  slot :content, required: true

  def page_panel(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-5 py-10 text-zinc-300" id={@id}>
      <section aria-labelledby={"#{@id}-title"}>
        <div class="mb-8 flex items-end justify-between flex-wrap gap-4">
          <div>
            <div class="flex items-center gap-4">
              {render_slot(@title_area)}
              <h1
                id={"#{@id}-title"}
                class="font-brand font-extrabold text-white text-2xl sm:text-3xl leading-tight tracking-tight"
              >
                {@title}
              </h1>
            </div>
            <%= if @description != [] do %>
              <p class="mt-3 text-zinc-400 max-w-md text-sm">
                {render_slot(@description)}
              </p>
            <% end %>
          </div>
          <div class="flex items-center gap-2">
            {render_slot(@call_to_action)}
          </div>
        </div>

        <%= if @navigation != [] do %>
          <div class="mb-4">
            {render_slot(@navigation)}
          </div>
        <% end %>

        <div class="rounded-xl border border-[#241b39] bg-[#141021] overflow-hidden shadow-[0_0_60px_-15px_rgba(148,40,236,0.5)]">
          <%= if @titlebar != [] do %>
            <div class="flex items-center gap-2 px-4 h-9 border-b border-[#241b39] bg-black/30 text-[11px] text-zinc-500 font-mono">
              <span class="flex gap-1.5" aria-hidden="true">
                <span class="w-3 h-3 rounded-full bg-brand-500"></span>
                <span class="w-3 h-3 rounded-full bg-accent-400"></span>
                <span class="w-3 h-3 rounded-full bg-zinc-600"></span>
              </span>
              {render_slot(@titlebar)}
            </div>
          <% end %>
          <div class="p-6">
            {render_slot(@content)}
          </div>
        </div>
      </section>
    </div>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="phx-no-feedback:hidden mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :form, :any, required: true
  attr :field, :atom, required: true

  def errors(assigns) do
    ~H"""
    <.error :for={msg <- translate_errors(@form.errors || [], @field)}>{msg}</.error>
    """
  end

  @doc """
  Translates an error message.
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

  # Bare form-field components.
  #
  # These render *only* the form element — no wrapping label, error, or styled
  # container — so callers keep full control of layout and styling. They replace the
  # `PhoenixHTMLHelpers.Form` functions (text_input/textarea/radio_button/select/label)
  # so the app no longer depends on `phoenix_html_helpers`. Pass a form field via
  # `f[:name]` access, which yields a `Phoenix.HTML.FormField` carrying id/name/value.

  @doc "A `<label>` whose `for` points at the given field's input id."
  attr :field, Phoenix.HTML.FormField, required: true
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def field_label(assigns) do
    ~H"""
    <label for={@field.id} class={@class}>{render_slot(@inner_block)}</label>
    """
  end

  @doc "A bare `<input>` (text and other single-value types) bound to a field."
  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :class, :any, default: nil

  attr :rest, :global,
    include:
      ~w(autocomplete autofocus disabled inputmode list max maxlength min minlength pattern placeholder readonly required size spellcheck step)

  def field_input(assigns) do
    ~H"""
    <input
      type={@type}
      id={@field.id}
      name={@field.name}
      value={Phoenix.HTML.Form.normalize_value(@type, @field.value)}
      class={@class}
      {@rest}
    />
    """
  end

  @doc "A bare `<textarea>` bound to a field."
  attr :field, Phoenix.HTML.FormField, required: true
  attr :class, :any, default: nil

  attr :rest, :global,
    include:
      ~w(autofocus cols disabled maxlength minlength placeholder readonly required rows spellcheck wrap)

  def field_textarea(assigns) do
    ~H"""
    <textarea id={@field.id} name={@field.name} class={@class} {@rest}>{Phoenix.HTML.Form.normalize_value("textarea", @field.value)}</textarea>
    """
  end

  @doc "A single `<input type=radio>` for `value`, checked when it matches the field's value."
  attr :field, Phoenix.HTML.FormField, required: true
  attr :value, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def field_radio(assigns) do
    ~H"""
    <input
      type="radio"
      id={"#{@field.id}_#{@value}"}
      name={@field.name}
      value={@value}
      checked={to_string(@field.value) == @value}
      class={@class}
      {@rest}
    />
    """
  end

  @doc "A bare `<select>` (set `multiple` for multi-select) bound to a field."
  attr :field, Phoenix.HTML.FormField, required: true
  attr :options, :list, required: true
  attr :multiple, :boolean, default: false
  attr :prompt, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(autocomplete disabled required size)

  def field_select(assigns) do
    ~H"""
    <select
      id={@field.id}
      name={if @multiple, do: @field.name <> "[]", else: @field.name}
      multiple={@multiple}
      class={@class}
      {@rest}
    >
      <option :if={@prompt} value="">{@prompt}</option>
      {Phoenix.HTML.Form.options_for_select(@options, @field.value)}
    </select>
    """
  end

  @doc "A `<span>` marking a regex match (`:matched`) or non-match segment."
  attr :type, :atom, required: true
  attr :string, :string, required: true

  def match_span(assigns) do
    ~H"""
    <span class={if @type == :matched, do: "m", else: "u"}>{@string}</span>
    """
  end
end
