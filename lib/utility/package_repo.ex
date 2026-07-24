defmodule Utility.PackageRepo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :utility,
    adapter: Etso.Adapter
end
