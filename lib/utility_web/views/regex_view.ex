defmodule UtilityWeb.RegexView do
  use UtilityWeb, :view
  alias Phoenix.LiveView.JS

  def changed?(changeset) do
    Map.take(changeset.changes, [:regex, :string, :flags, :function]) != %{}
  end

  def help_tab_options() do
    [
      {"Cheatsheet", "cheatsheet"},
      {"Flags", "flags"},
      {"Recipes", "recipes"}
    ]
  end

  def span_match(type, string) do
    content_tag(:span, string, class: (type == :matched && "m") || "u")
  end
end
