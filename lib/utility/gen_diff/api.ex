defmodule Utility.GenDiff.Api do
  @moduledoc """
  Orchestrates the on-demand Markdown API: validate params into a `Generator`, then
  return the assembled Markdown, building the diff on demand if it isn't cached.

  Caching is layered by the generator's deterministic id: the assembled `.md` is
  served directly on a hit; otherwise the raw `.patch` is used (or built) and the
  `.md` is assembled and cached for next time.
  """
  alias Utility.GenDiff.{Changelog, Generator, Markdown, Storage}
  alias Utility.Workers.GenerateDiff

  @default_timeout :timer.seconds(180)

  @typedoc "Builds the URL of a single file's patch, given the generator and file path."
  @type file_url :: (Generator.t(), binary() -> binary())

  @doc """
  Returns `{:ok, index_markdown}` for the index document.

  `opts[:file_url]` (required) is a 2-arity function `(generator, file_path) -> url`
  used to link each changed file to its per-file patch endpoint.

  Other returns: `{:error, :invalid, changeset}` for bad params, `{:error,
  :build_failed}` if the diff build errors, `{:error, :timeout}` on timeout.
  """
  @spec markdown(map(), keyword()) ::
          {:ok, binary()}
          | {:error, :invalid, Ecto.Changeset.t()}
          | {:error, :build_failed}
          | {:error, :timeout}
  def markdown(params, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    file_url = Keyword.fetch!(opts, :file_url)
    changelog_url = Keyword.fetch!(opts, :changelog_url)

    with {:ok, generator} <- apply_generator(params) do
      cl_url = if Changelog.supported?(generator.project), do: changelog_url.(generator)
      fetch_or_build(generator, params, timeout, &file_url.(generator, &1), cl_url)
    end
  end

  @doc """
  Returns `{:ok, changelog_markdown}` — the upstream CHANGELOG sliced to this version
  range — or `{:error, :unsupported}` / `{:error, :unavailable}`. Served as its own
  file so its markdown headings don't collide with the index document.
  """
  @spec changelog(map(), keyword()) ::
          {:ok, binary()} | {:error, :invalid, Ecto.Changeset.t()} | {:error, atom()}
  def changelog(params, _opts \\ []) do
    with {:ok, generator} <- apply_generator(params) do
      Changelog.slice(generator.project, generator.from_version, generator.to_version)
    end
  end

  @doc """
  Returns `{:ok, file_diff}` — the standalone unified diff for one `file` in the diff —
  or `{:error, :not_in_diff}` if that file didn't change. Same error tuples as
  `markdown/2` otherwise. Builds the diff on demand if it isn't cached.
  """
  @spec file_patch(map(), binary(), keyword()) ::
          {:ok, binary()}
          | {:error, :invalid, Ecto.Changeset.t()}
          | {:error, :not_in_diff}
          | {:error, :build_failed}
          | {:error, :timeout}
  def file_patch(params, file, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    with {:ok, generator} <- apply_generator(params),
         {:ok, patch} <- ensure_patch(generator, params, timeout) do
      extract_file(patch, file)
    end
  end

  defp apply_generator(params) do
    case Generator.apply(params) do
      {:ok, generator} -> {:ok, generator}
      {:error, changeset} -> {:error, :invalid, changeset}
    end
  end

  defp extract_file(patch, file) do
    case Markdown.file_patch(patch, file) do
      nil -> {:error, :not_in_diff}
      file_diff -> {:ok, file_diff}
    end
  end

  defp fetch_or_build(generator, params, timeout, file_url, changelog_url) do
    case Storage.get_md(generator) do
      {:ok, md} ->
        {:ok, md}

      {:error, :not_found} ->
        with {:ok, patch} <- ensure_patch(generator, params, timeout) do
          md = Markdown.index(generator, patch, file_url, changelog_url)
          Storage.put_md(generator, md)
          {:ok, md}
        end
    end
  end

  defp ensure_patch(generator, params, timeout) do
    case Storage.get_patch(generator) do
      {:ok, patch} -> {:ok, patch}
      {:error, :not_found} -> build(generator, params, timeout)
    end
  end

  defp build(generator, params, timeout) do
    topic = "hexgen:progress:#{generator.project}:#{generator.id}"
    :ok = Phoenix.PubSub.subscribe(Utility.PubSub, topic)

    # unique dedupes concurrent identical requests onto a single build.
    %{"generator" => params}
    |> GenerateDiff.new(unique: [period: 300])
    |> Oban.insert()

    deadline = System.monotonic_time(:millisecond) + timeout
    result = wait_for_build(deadline)
    Phoenix.PubSub.unsubscribe(Utility.PubSub, topic)

    case result do
      :finished -> patch_or_empty(generator)
      :error -> {:error, :build_failed}
      :timeout -> {:error, :timeout}
    end
  end

  # After a successful build the patch is always written (empty string when the two
  # apps are identical), so a miss here means something went wrong.
  defp patch_or_empty(generator) do
    case Storage.get_patch(generator) do
      {:ok, patch} -> {:ok, patch}
      {:error, :not_found} -> {:error, :build_failed}
    end
  end

  defp wait_for_build(deadline) do
    remaining = deadline - System.monotonic_time(:millisecond)

    if remaining <= 0 do
      :timeout
    else
      receive do
        {:progress, _, "all-finished"} -> :finished
        {:progress, _, "all-finished-error"} -> :error
        {:progress, _, _} -> wait_for_build(deadline)
      after
        remaining -> :timeout
      end
    end
  end
end
