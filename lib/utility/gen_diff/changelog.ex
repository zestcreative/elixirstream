defmodule Utility.GenDiff.Changelog do
  @moduledoc """
  Fetches a project's `CHANGELOG.md` and slices out the sections relevant to an
  upgrade — the release-highlights preamble plus the version sections in the range
  `from < version <= to`.

  Only projects with a known changelog source are supported (currently Phoenix via
  `phx_new`); others return `{:error, :unsupported}`. The fetched changelog is cached
  so repeated builds don't refetch.
  """
  alias Utility.Cache

  # `%REF%` is replaced with the git ref (a `v<version>` tag, or `main`).
  @sources %{
    "phx_new" => "https://raw.githubusercontent.com/phoenixframework/phoenix/%REF%/CHANGELOG.md"
  }

  @branches ~w[main master]

  @doc "Whether a changelog source is known for the given project."
  @spec supported?(String.t()) :: boolean()
  def supported?(project), do: Map.has_key?(@sources, project)

  @spec slice(String.t(), String.t(), String.t()) :: {:ok, String.t()} | {:error, atom()}
  def slice(project, from_version, to_version) do
    with {:ok, template} <- source(project) do
      # An upgrade can span multiple series (e.g. 1.7.6 -> 1.8.3), and each series has
      # its own changelog file. Slice every series in range and concatenate (newest first).
      combined =
        project
        |> refs_in_range(from_version, to_version)
        |> Enum.map(&slice_ref(project, template, &1, from_version, to_version))
        |> Enum.reject(&(&1 == ""))
        |> Enum.join("\n\n")

      if combined == "", do: {:error, :unavailable}, else: {:ok, combined}
    end
  end

  defp slice_ref(project, template, ref, from_version, to_version) do
    case fetch(project, template, ref) do
      {:ok, raw} -> slice_text(raw, from_version, to_version)
      _ -> ""
    end
  end

  @doc """
  Pre-fetch and cache the changelog for every supported version series. Best-effort;
  meant to run at boot so runtime requests hit the on-disk cache instead of GitHub.
  """
  def warm(project) do
    case source(project) do
      {:ok, template} -> Enum.each(series_refs(project), &fetch(project, template, &1))
      {:error, _} -> :ok
    end

    :ok
  end

  @doc "Wait for package versions to load, then `warm/1`. Never raises. For boot."
  def warm_on_boot(project \\ "phx_new") do
    wait_for_versions(project, 15)
    warm(project)
  rescue
    _ -> :ok
  catch
    _, _ -> :ok
  end

  defp source(project) do
    case Map.fetch(@sources, project) do
      {:ok, template} -> {:ok, template}
      :error -> {:error, :unsupported}
    end
  end

  defp fetch(project, template, ref) do
    case Cache.hash_get(cache_key(project), ref) do
      {:ok, raw} when is_binary(raw) -> {:ok, raw}
      _ -> fetch_and_cache(project, template, ref)
    end
  end

  # The git refs whose changelogs cover the `(from, to]` range — one per series in
  # range (each is that series' latest patch, so every 1.8.x shares one cached file),
  # newest series first. `main` and unparseable versions fall back to a single ref.
  defp refs_in_range(_project, _from, to) when to in @branches, do: ["main"]

  defp refs_in_range(project, from_version, to_version) do
    with {:ok, from} <- Version.parse(from_version),
         {:ok, to} <- Version.parse(to_version) do
      from_series = {from.major, from.minor}
      to_series = {to.major, to.minor}

      project
      |> series_tags()
      |> Enum.filter(fn {series, _ref} -> series >= from_series and series <= to_series end)
      |> Enum.sort_by(fn {series, _ref} -> series end, :desc)
      |> Enum.map(fn {_series, ref} -> ref end)
    else
      _ -> ["v#{to_version}"]
    end
  end

  defp series_refs(project), do: project |> series_tags() |> Map.values()

  # %{{major, minor} => "v<latest-patch-in-series>"}
  defp series_tags(project) do
    project
    |> available_versions()
    |> Enum.flat_map(fn v ->
      case Version.parse(v) do
        {:ok, parsed} -> [parsed]
        :error -> []
      end
    end)
    |> Enum.group_by(&{&1.major, &1.minor})
    |> Map.new(fn {series, versions} ->
      {series, "v" <> to_string(Enum.max(versions, Version))}
    end)
  end

  defp available_versions(project) do
    case Utility.PackageRepo.get_by(Utility.Package, name: project) do
      %{versions: versions} when is_list(versions) -> versions
      _ -> []
    end
  end

  defp wait_for_versions(_project, 0), do: :ok

  defp wait_for_versions(project, tries) do
    if available_versions(project) == [] do
      Process.sleep(2000)
      wait_for_versions(project, tries - 1)
    else
      :ok
    end
  end

  defp fetch_and_cache(project, template, ref) do
    case get(String.replace(template, "%REF%", ref)) do
      {:ok, raw} ->
        # Version tags are immutable, so cache them permanently — a given version's
        # changelog is fetched from GitHub at most once, ever. `main` moves, so expire it.
        opts = if ref == "main", do: [expires_in: 3600], else: []
        Cache.hash_set(cache_key(project), ref, raw, opts)
        {:ok, raw}

      :error when ref != "main" ->
        # A tag might not exist (e.g. unusual version) — fall back to the main branch.
        fetch_and_cache(project, template, "main")

      :error ->
        {:error, :unavailable}
    end
  end

  defp get(url) do
    case Finch.request(Finch.build(:get, url), Utility.Finch, receive_timeout: 15_000) do
      {:ok, %Finch.Response{status: 200, body: body}} -> {:ok, body}
      _ -> :error
    end
  end

  defp cache_key(project), do: "changelog:#{project}"

  @doc """
  Slice raw changelog markdown to the `from < version <= to` range (plus the leading
  release-highlights preamble). Pure — exposed for testing.
  """
  @spec slice_text(String.t(), String.t(), String.t()) :: String.t()
  def slice_text(raw, from_version, to_version) do
    from = lower_bound(from_version)
    to = upper_bound(to_version)
    [title | sections] = String.split(raw, ~r/\n(?=## )/)

    {kept, _phase, kept_version?} =
      Enum.reduce_while(sections, {[title], :preamble, false}, fn section, {acc, phase, any} ->
        case header_version(section) do
          # Narrative section: keep the highlights above the versions; stop once we've
          # passed the version list (e.g. the trailing prior-series pointer).
          nil when phase == :preamble -> {:cont, {[section | acc], :preamble, any}}
          nil -> {:halt, {acc, :done, any}}
          version -> take_version(version, section, from, to, acc, any)
        end
      end)

    # A series with no version in range contributes nothing (avoids a bare preamble
    # when concatenating multiple series' changelogs).
    if kept_version? do
      kept |> Enum.reverse() |> Enum.join("\n") |> String.trim_trailing() |> Kernel.<>("\n")
    else
      ""
    end
  end

  # Changelogs are newest-first. Skip sections above `to` (the series-latest changelog
  # includes patches newer than the requested `to`), include those in `(from, to]`, and
  # halt once we reach a version at/below `from`.
  defp take_version(version, section, from, to, acc, any) do
    cond do
      above?(version, to) -> {:cont, {acc, :versions, any}}
      Version.compare(version, from) == :gt -> {:cont, {[section | acc], :versions, true}}
      true -> {:halt, {acc, :done, any}}
    end
  end

  defp above?(_version, :infinity), do: false
  defp above?(version, %Version{} = to), do: Version.compare(version, to) == :gt

  defp header_version("## " <> rest) do
    token =
      rest
      |> String.trim()
      |> String.split()
      |> List.first()
      |> to_string()
      |> String.trim_leading("v")

    case Version.parse(token) do
      {:ok, version} -> version
      :error -> nil
    end
  end

  defp header_version(_), do: nil

  defp lower_bound(version) when version in @branches, do: %Version{major: 0, minor: 0, patch: 0}
  defp lower_bound(version), do: Version.parse!(version)

  defp upper_bound(version) when version in @branches, do: :infinity
  defp upper_bound(version), do: Version.parse!(version)
end
