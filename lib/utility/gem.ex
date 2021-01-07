defmodule Utility.Gem do
  alias Utility.Gem.Api
  alias Utility.Package
  alias Utility.PackageRepo

  def cache_versions(:all) do
    Utility.GenDiff.Data.all()
    |> Stream.filter(fn {_name, project} -> project[:source] == :gem end)
    |> Stream.each(&cache_versions/1)
    |> Stream.run()
  end

  def cache_versions({package, _}) do
    PackageRepo.get(Package, package)
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
