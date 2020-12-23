defmodule Utility.Repo do
  use Ecto.Repo,
    otp_app: :utility,
    adapter: Ecto.Adapters.Postgres
end
