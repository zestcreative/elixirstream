defmodule Utility.GenDiff.Changelog do
  @moduledoc """
  Fetches a project's `CHANGELOG.md` and slices out the sections relevant to an
  upgrade — the release-highlights preamble plus the version sections in the range
  `from < version <= to`.

  Only projects with a known changelog source are supported (currently Phoenix via
  `phx_new`); others return `{:error, :unsupported}`. The fetched changelog is cached
  so repeated builds don't refetch.

  A generator's own changelog isn't the whole story: `phx.new` scaffolds an app whose
  deps carry most of the churn — the bulk of a 1.7 -> 1.8 upgrade is LiveView's, not
  Phoenix's. `companion_slices/2` covers every dep whose requirement moved, deriving
  each one's version range from the generated `mix.exs` in the diff.
  """
  alias Utility.Cache
  alias Utility.GenDiff.Markdown

  # `%REF%` is replaced with the git ref (a `v<version>` tag, or `main`).
  @sources %{
    "phx_new" => "https://raw.githubusercontent.com/phoenixframework/phoenix/%REF%/CHANGELOG.md"
  }

  # GitHub repos for the deps a generated app pins, all of which keep a root
  # CHANGELOG.md. A lookup table, not a fetch list: only deps whose requirement actually
  # changed in the diff's mix.exs get fetched, so a patch-level bump costs nothing.
  @companion_repos %{
    "bandit" => "mtrudel/bandit",
    "dns_cluster" => "phoenixframework/dns_cluster",
    "ecto" => "elixir-ecto/ecto",
    "ecto_sql" => "elixir-ecto/ecto_sql",
    "esbuild" => "phoenixframework/esbuild",
    "finch" => "sneako/finch",
    "floki" => "philss/floki",
    "gettext" => "elixir-gettext/gettext",
    "jason" => "michalmuskala/jason",
    "lazy_html" => "dashbitco/lazy_html",
    "phoenix_ecto" => "phoenixframework/phoenix_ecto",
    "phoenix_html" => "phoenixframework/phoenix_html",
    "phoenix_live_dashboard" => "phoenixframework/phoenix_live_dashboard",
    "phoenix_live_reload" => "phoenixframework/phoenix_live_reload",
    "phoenix_live_view" => "phoenixframework/phoenix_live_view",
    "phoenix_pubsub" => "phoenixframework/phoenix_pubsub",
    "phoenix_template" => "phoenixframework/phoenix_template",
    "phoenix_view" => "phoenixframework/phoenix_view",
    "plug" => "elixir-plug/plug",
    "plug_crypto" => "elixir-plug/plug_crypto",
    "req" => "wojtekmach/req",
    "swoosh" => "swoosh/swoosh",
    "tailwind" => "phoenixframework/tailwind",
    "telemetry" => "beam-telemetry/telemetry",
    "telemetry_metrics" => "beam-telemetry/telemetry_metrics",
    "telemetry_poller" => "beam-telemetry/telemetry_poller"
  }

  @branches ~w[main master]

  @doc "Whether a changelog source is known for the given project."
  @spec supported?(String.t()) :: boolean()
  def supported?(project), do: Map.has_key?(@sources, project)

  @doc "Every companion package name, so their versions get cached alongside generators'."
  @spec companion_packages() :: [String.t()]
  def companion_packages, do: Map.keys(@companion_repos)

  @doc """
  The library a project's changelog is actually about. `phx_new` is the installer
  package, but its changelog source is the `phoenix` repo — labelling it "phx_new" is
  misleading, so the name comes from the source URL rather than the project key.
  """
  @spec changelog_name(String.t()) :: String.t()
  def changelog_name(project) do
    with {:ok, template} <- source(project),
         [_, repo] <- Regex.run(~r{githubusercontent\.com/[^/]+/([^/]+)/}, template) do
      repo
    else
      _ -> project
    end
  end

  @spec slice(String.t(), String.t(), String.t()) :: {:ok, String.t()} | {:error, atom()}
  def slice(project, from_version, to_version) do
    with {:ok, template} <- source(project) do
      combined = slice_package(project, template, from_version, to_version)
      if informative?(combined), do: {:ok, combined}, else: {:error, :unavailable}
    end
  end

  # A slice with no version sections is just a title and maybe a preamble — nothing
  # actually changed in this range, so callers should show nothing rather than an
  # empty box.
  defp informative?(markdown) do
    markdown |> String.split(~r/\n(?=## )/) |> Enum.any?(&header_version/1)
  end

  @doc """
  Changelog slices for the deps the generated app pins, as `[{package, markdown}]` — one
  entry per dep, so each can be served on its own rather than as one concatenated blob.

  The version range can't come from the generator's version — `phx.new` 1.7.14 pins
  `phoenix_live_view ~> 1.0.0-rc.1` while 1.8.0 pins `~> 1.1.0`, and nothing about
  "1.7.14 -> 1.8.0" predicts that. The generated `mix.exs` is the only ground truth,
  and it's already in the diff, so each range is read straight off its `-`/`+` lines.

  Deps whose requirement is unchanged are skipped — there's nothing to report — which
  is what keeps this proportional to the size of the upgrade. Pass `only` to fetch a
  single dep's changelog instead of every changed one.
  """
  @spec companion_slices(String.t() | nil, [String.t()] | :all) :: [{String.t(), String.t()}]
  def companion_slices(patch, only \\ :all) do
    patch
    |> changed_deps()
    |> Enum.filter(fn {package, _, _} -> only == :all or package in only end)
    |> Task.async_stream(&companion_slice/1, timeout: :infinity, ordered: true)
    |> Enum.flat_map(fn
      {:ok, {package, md}} -> if informative?(md), do: [{package, md}], else: []
      _ -> []
    end)
  end

  defp companion_slice({package, from_req, to_req}) do
    template = "https://raw.githubusercontent.com/#{@companion_repos[package]}/%REF%/CHANGELOG.md"

    case companion_range(package, from_req, to_req) do
      {:ok, from, to} -> {package, slice_package(package, template, from, to)}
      _ -> {package, ""}
    end
  end

  @doc """
  The deps whose requirement moved, as `[{package, from_req, to_req}]`, read off the
  `mix.exs` in `patch`. The generated mix.exs pins deps as `{:phoenix_live_view, "~> 1.1.0"}`;
  a dep counts only if it appears on both the removed and added side with a different
  requirement, and only if we know where its changelog lives.

  Pure and network-free — the API uses it to list what changed without fetching anything.
  LiveView sorts first (the rest alphabetically) because for a Phoenix upgrade it's the
  one that matters most; callers surface it right after the generator's own changelog.
  """
  @spec changed_deps(binary() | nil) :: [{binary(), binary(), binary()}]
  def changed_deps(nil), do: []

  def changed_deps(patch) do
    patch |> Markdown.file_patch("mix.exs") |> deps_from_mix_exs()
  end

  defp deps_from_mix_exs(nil), do: []

  defp deps_from_mix_exs(mix_exs_diff) do
    lines = String.split(mix_exs_diff, "\n")
    removed = dep_reqs(lines, "-")
    added = dep_reqs(lines, "+")

    for {package, from_req} <- removed,
        Map.has_key?(@companion_repos, package),
        to_req = added[package],
        to_req not in [nil, from_req] do
      {package, from_req, to_req}
    end
    |> Enum.sort_by(fn {package, _, _} -> {package != "phoenix_live_view", package} end)
  end

  # Anchoring the tuple to the start of the line (past indentation) is what keeps commented
  # -out deps out — phx.new 1.7.14 ships a literal `# TODO bump on release to
  # {:phoenix_live_view, "~> 1.0.0"},` right above the real pin. `--- a/mix.exs` and
  # `+++ b/mix.exs` can't match either, so there's nothing else to skip.
  defp dep_reqs(lines, prefix) do
    for line <- lines,
        [_, package, req] <- [Regex.run(~r/^\Q#{prefix}\E\s*\{:(\w+),\s*"([^"]+)"/, line)],
        into: %{},
        do: {package, req}
  end

  # An upgrade can span multiple series (e.g. 1.7.6 -> 1.8.3). Phoenix and LiveView keep
  # one changelog file per series, so slice every series ref in range and concatenate
  # (newest first). Most other deps keep a single all-history CHANGELOG.md, where every
  # ref yields the same slice — hence the dedupe.
  defp slice_package(package, template, from_version, to_version) do
    package
    |> refs_in_range(from_version, to_version)
    |> Enum.map(&slice_ref(package, template, &1, from_version, to_version))
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n\n")
    |> dedupe_sections()
  end

  defp dedupe_sections(""), do: ""

  defp dedupe_sections(markdown) do
    markdown
    |> String.split(~r/\n(?=## )/)
    |> Enum.with_index()
    # Keyed on the version, not the heading text: two series' highlights can both be
    # titled `## Deprecations` and both belong here. Non-version sections key on their
    # index so they're never collapsed.
    |> Enum.uniq_by(fn {section, index} -> header_version(section) || index end)
    |> Enum.map_join("\n", fn {section, _index} -> section end)
  end

  defp slice_ref(project, template, ref, from_version, to_version) do
    case fetch(project, template, ref) do
      {:ok, raw} -> slice_text(raw, from_version, to_version)
      _ -> ""
    end
  end

  # Both bounds come from the real release list, not from the requirement's base version.
  #
  # `to` is the newest release the new requirement allows — what a fresh app gets from Hex.
  #
  # `from` is the newest release the OLD requirement allowed that the new one does *not*.
  # Resolving from_req on its own doesn't work: a two-segment `~> 0.3` permits everything
  # below 1.0.0, so it lands on the same version as `~> 0.5` and the range collapses to
  # empty. And using the requirement's base (1.1.0 for `~> 1.1.0`) goes the other way,
  # sweeping in that dep's entire previous series. Where the old requirement topped out
  # before the new one took over is the range that actually describes the bump.
  @doc "The resolved `{:ok, from, to}` changelog bounds for a dep bump. Exposed for testing."
  @spec companion_range(String.t(), String.t(), String.t()) ::
          {:ok, String.t(), String.t()} | :error
  def companion_range(package, from_req, to_req) do
    with {:ok, from_r} <- Version.parse_requirement(from_req),
         {:ok, to_r} <- Version.parse_requirement(to_req),
         versions = parsed_versions(package),
         {:ok, to} <- newest(versions, &satisfies?(&1, to_r)),
         {:ok, from} <-
           newest(versions, &(satisfies?(&1, from_r) and not satisfies?(&1, to_r))) do
      {:ok, to_string(from), to_string(to)}
    else
      _ -> base_range(from_req, to_req)
    end
  end

  # `allow_pre: false` mirrors how Hex resolves: a pre-release is only picked when the
  # requirement itself names one. Without it, `~> 1.1.0` would resolve to `1.2.0-rc.3`
  # (which is genuinely `< 1.2.0`) rather than to the newest stable 1.1.x.
  defp satisfies?(version, requirement),
    do: Version.match?(version, requirement, allow_pre: false)

  defp newest(versions, pred) do
    case Enum.filter(versions, pred) do
      [] -> :error
      matching -> {:ok, Enum.max(matching, Version)}
    end
  end

  # Used when the package's Hex versions haven't been cached yet — over-inclusive, but a
  # changelog that's too long beats one that silently omits the breaking change.
  defp base_range(from_req, to_req) do
    with {:ok, from} <- req_base(from_req),
         {:ok, to} <- req_base(to_req) do
      {:ok, to_string(from), to_string(to)}
    end
  end

  defp req_base(req) do
    case Regex.run(~r/(\d+)\.(\d+)(?:\.(\d+))?(-[\w.]+)?/, req) do
      [_, major, minor] -> Version.parse("#{major}.#{minor}.0")
      [_, major, minor, patch] -> Version.parse("#{major}.#{minor}.#{patch}")
      [_, major, minor, patch, pre] -> Version.parse("#{major}.#{minor}.#{patch}#{pre}")
      _ -> :error
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
      |> known_series()
      |> Enum.filter(&(&1 >= from_series and &1 <= to_series))
      |> Enum.sort(:desc)
      |> Enum.map(&series_ref/1)
      |> case do
        [] -> [series_ref(to_series)]
        refs -> refs
      end
    else
      _ -> ["main"]
    end
  end

  # A `vMAJOR.MINOR` maintenance branch, not a version tag. Tags point at the commit
  # *before* the release notes land — `tailwind` at tag `v0.5.1` still reads
  # "## v0.5.0 (Unreleased)" — so a tag reliably omits the newest release, the one most
  # worth reading. Projects without maintenance branches (most deps keep a single
  # all-history CHANGELOG) 404 here and fall back to `main`, which is what they want.
  defp series_ref({major, minor}), do: "v#{major}.#{minor}"

  defp series_refs(project), do: project |> known_series() |> Enum.map(&series_ref/1)

  # Every `{major, minor}` series the package has released, from its Hex versions.
  defp known_series(project) do
    project |> parsed_versions() |> Enum.map(&{&1.major, &1.minor}) |> Enum.uniq()
  end

  defp parsed_versions(project) do
    project
    |> available_versions()
    |> Enum.flat_map(fn v ->
      case Version.parse(v) do
        {:ok, parsed} -> [parsed]
        :error -> []
      end
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
        # Every ref is a branch now (`vMAJOR.MINOR` or `main`), and branches move as
        # patches land, so nothing can be cached permanently.
        Cache.hash_set(cache_key(project), ref, raw, expires_in: 3600)
        {:ok, raw}

      :error when ref != "main" ->
        # Most packages have no maintenance branches — they keep one all-history
        # CHANGELOG on the default branch, which covers every series anyway.
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
