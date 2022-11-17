defmodule Utility.Repo do
  use Ecto.Repo,
    otp_app: :utility,
    adapter: Ecto.Adapters.Postgres

  use Quarto, limit: 25
end
