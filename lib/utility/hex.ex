defmodule Utility.Hex do
  @moduledoc false
  alias Utility.Hex.Api
  alias Utility.Package
  alias Utility.PackageRepo

  def cache_versions(:all) do
    generators =
      Utility.GenDiff.Data.all()
      |> Stream.filter(fn {_name, project} -> project[:source] == :hex end)
      |> Stream.map(fn {name, _} -> name end)

    # Companions aren't generators, but their versions resolve a `~> 1.1.0` requirement
    # to the newest 1.1.x when slicing their changelogs.
    generators
    |> Stream.concat(Utility.GenDiff.Changelog.companion_packages())
    |> Stream.uniq()
    |> Stream.each(&cache_versions/1)
    |> Stream.run()
  end

  def cache_versions(package) when is_binary(package), do: cache_versions({package, nil})

  def cache_versions({package, _}) do
    Package
    |> PackageRepo.get(package)
    |> case do
      nil -> %Package{name: package}
      package -> package
    end
    |> Package.changeset(%{
      name: package,
      versions: Api.get_versions(package)
    })
    |> PackageRepo.insert_or_update!()
  end
end
