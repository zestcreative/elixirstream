defmodule Utility.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      UtilityWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Utility.PubSub},
      # Start the Endpoint (http/https)
      UtilityWeb.Endpoint,
      Utility.Redix
      # Start a worker by calling: Utility.Worker.start_link(arg)
      # {Utility.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Utility.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    UtilityWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
