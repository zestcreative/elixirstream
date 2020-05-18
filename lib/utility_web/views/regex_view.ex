defmodule UtilityWeb.RegexView do
  use UtilityWeb, :view

  def changed?(changeset) do
    Map.take(changeset.changes, [:regex, :string, :flags, :function]) != %{}
  end
end
