defmodule Utility.Gem.Api do
  import Utility.ProjectRunner, only: [path_for: 1]

  @gem_search "bin/gemsearch.sh"
  def get_versions(package) do
    @gem_search
    |> path_for()
    |> Path.expand()
    |> System.cmd([package])
    |> case do
      {versions, 0} ->
        versions |> String.trim() |> String.split("\n")
      {_, _} ->
        []
    end
    |> Enum.map(&conform_semver/1)
    |> Enum.filter(fn version_string ->
      case Version.parse(version_string) do
        {:ok, version} -> allow_package_version(package, version)
        :error -> false
      end
    end)
    |> Enum.sort({:desc, Version})
  end

  @rails_limit_before Version.parse!("3.0.0")
  defp allow_package_version("rails", version) do
    Version.compare(version, @rails_limit_before) != :lt
  end

  @webpacker_limit_before Version.parse!("1.2.0")
  defp allow_package_version("webpacker", version) do
    Version.compare(version, @webpacker_limit_before) != :lt
  end

  defp allow_package_version(_package, _version), do: true

  defp conform_semver(version_string) when byte_size(version_string) == 3 do
    version_string <> ".0"
  end
  defp conform_semver(version), do: version
end
