defmodule UtilityWeb.RegexView do
  use UtilityWeb, :view

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
end
