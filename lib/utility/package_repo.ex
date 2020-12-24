defmodule Utility.PackageRepo do
  use Ecto.Repo,
    otp_app: :utility,
    adapter: Etso.Adapter
end
