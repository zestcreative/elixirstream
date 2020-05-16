defmodule UtilityWeb.RegexView do
  use UtilityWeb, :view

  def changed?(changeset) do
    Map.drop(changeset.changes, [:result]) != %{}
  end
end
