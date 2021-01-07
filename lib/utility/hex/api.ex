defmodule Utility.Hex.Api do
  @moduledoc "Mostly copied from diff.hex.pm"
  require Logger

  @config %{
    :hex_core.default_config()
    | http_adapter: {Utility.Hex.Api.Adapter, %{}},
      http_user_agent_fragment: "hexpm_diff"
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
      |> Enum.sort({:desc, Version})
    end
  end
end
