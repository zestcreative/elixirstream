defmodule Utility.Redix do
  @moduledoc false
  @pool_size Application.compile_env(:utility, :redis_pool_size)

  def child_spec(_args) do
    # Specs for the Redix connections.
    redis_url = URI.parse(Application.get_env(:utility, :redis_url))
    password = redis_url.userinfo && List.last(String.split(redis_url.userinfo, ":"))
    database = (redis_url.path || "/0") |> String.split("/") |> List.last() |> String.to_integer()
    maybe_ip6 = if Application.get_env(:utility, :redis_ip6), do: [socket_opts: [:inet6]], else: []

    children =
      for i <- 0..(@pool_size - 1) do
        Supervisor.child_spec(
          {Redix,
           [
             host: redis_url.host,
             port: redis_url.port,
             password: password,
             name: :"redix_#{i}",
             database: database
           ] ++ maybe_ip6},
          id: {Redix, i}
        )
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
