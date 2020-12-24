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
      Enum.map(package_versions, & &1[:version])
    end
  end

  def get_tarball(package, version) do
    with {:ok, {200, _, tarball}} <- :hex_repo.get_tarball(@config, package, version) do
      {:ok, tarball, :hex}
    else
      {:ok, {403, _, _}} ->
        {:error, :not_found}

      {:ok, {status, _, _}} ->
        Logger.error("Failed to get package versions. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get tarball for package: #{package}. Reason: #{inspect(reason)}.")
        {:error, :not_found}
    end
  end

  def unpack_tarball(tarball, path) when is_binary(path) do
    path = to_charlist(path)

    with {:ok, _} <- :hex_tarball.unpack(tarball, path) do
      :ok
    end
  end

  def get_checksums(package, versions) do
    with {:ok, {200, _, releases}} <- :hex_repo.get_package(@config, package) do
      checksums =
        for release <- releases, release.version in versions do
          release.outer_checksum
        end

      {:ok, checksums}
    else
      {:ok, {status, _, _}} ->
        Logger.error("Failed to get checksums for package: #{package}. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error(
          "Failed to get checksums for package: #{package}. Reason: #{inspect(reason)}"
        )

        {:error, :not_found}
    end
  end
end
