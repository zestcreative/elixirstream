defmodule Utility.Hex.Api do
  @moduledoc "Mostly copied from diff.hex.pm"
  require Logger

  @config %{
    :hex_core.default_config()
    | http_adapter: {Utility.Hex.Api.Adapter, %{}},
      http_user_agent_fragment: "elixirstreamdev_diff"
  }

  def get_package(package) do
    with {:ok, {200, _, results}} <- :hex_repo.get_package(@config, package) do
      {:ok, results}
    else
      {:ok, {_status, _, _}} ->
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get package versions. Reason: #{inspect(reason)}.")
        {:error, :not_found}
    end
  end

  def get_versions(package) do
    with {:ok, package_versions} <- get_package(package) do
      package_versions
      |> Enum.map(& &1[:version])
      |> get_nonhex_versions(package)
      |> Enum.sort({:desc, Version})
      |> get_nonstandard_versions(package)
    end
  end

  @phoenix_new_versions ~w[1.0.0 1.0.1 1.0.2 1.0.3 1.0.4 1.1.0 1.1.1 1.1.2 1.1.3 1.1.4 1.1.5 1.1.6
    1.1.9 1.2.0 1.2.1 1.2.4 1.2.5]
  @phx_new_versions ~w[1.3.0 1.3.1 1.3.2 1.3.3 1.3.4]
  defp get_nonhex_versions(versions, "phx_new") do
    @phoenix_new_versions ++ @phx_new_versions ++ versions
  end

  defp get_nonhex_versions(versions, _), do: versions

  defp get_nonstandard_versions(versions, "phx_new"), do: versions ++ ["main"]
  defp get_nonstandard_versions(versions, _), do: versions
end
