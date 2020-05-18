defmodule Utility.Redix do
  @pool_size 5

  def child_spec(_args) do
    # Specs for the Redix connections.
    redis_url = URI.parse(System.get_env("REDIS_URL") || "redis://127.0.0.1:6379")
    children =
      for i <- 0..(@pool_size - 1) do
        Supervisor.child_spec({Redix, redis_url, name: :"redix_#{i}"}, id: {Redix, i})
      end

    # Spec for the supervisor that will supervise the Redix connections.
    %{
      id: RedixSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  def command(command) do
    Redix.command(:"redix_#{random_index()}", command)
  end

  def pipeline(command) do
    Redix.pipeline(:"redix_#{random_index()}", command)
  end

  defp random_index() do
    rem(System.unique_integer([:positive]), @pool_size)
  end
end
