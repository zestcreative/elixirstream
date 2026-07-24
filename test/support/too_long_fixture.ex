defmodule Utility.Test.TooLong do
  @moduledoc false
  @too_long Enum.join(Enum.take(Stream.cycle(["x"]), 2_000_001))

  def too_long, do: @too_long
end
