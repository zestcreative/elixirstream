defmodule UtilityWeb.GenDiffHTML do
  use UtilityWeb, :html
  require Logger

  embed_templates "gen_diff_html/*"

  # Dark theme to match the gendiff page; styles are inlined into the HTML so no
  # extra stylesheet is needed. Powered by MDEx + the lumis highlighter.
  @changelog_theme "github_dark"

  @doc """
  Render the (trusted, upstream) changelog Markdown to safe HTML with syntax-highlighted
  code blocks. MDEx escapes raw inline HTML by default, so this is XSS-safe.
  """
  def render_changelog(markdown) do
    markdown
    |> MDEx.to_html!(syntax_highlight: [formatter: {:html_inline, theme: @changelog_theme}])
    |> Phoenix.HTML.raw()
  end

  @doc "The sliced upstream changelog for this diff's version range, or nil."
  def changelog(generator) do
    case Utility.GenDiff.Changelog.slice(
           generator.project,
           generator.from_version,
           generator.to_version
         ) do
      {:ok, changelog} -> changelog
      {:error, _} -> nil
    end
  end

  @doc "Absolute URL of the LLM-friendly Markdown version of this diff."
  def md_url(generator) do
    url(
      ~p"/gendiff/api?#{[project: generator.project, command: generator.command, from: generator.from_version, to: generator.to_version, from_flags: Enum.join(generator.from_flags || [], ","), to_flags: Enum.join(generator.to_flags || [], ",")]}"
    )
  end

  def render_diff(stream, generator) do
    path = tmp_path("html-#{generator.project}-#{generator.id}-")
    Logger.info("Rendering diff #{generator.id} to #{path}")

    File.open!(path, [:write, :raw, :binary, :write_delay], fn file ->
      html_patch =
        Phoenix.Template.render_to_iodata(__MODULE__, "diff_header", "html",
          generator: generator,
          changelog: changelog(generator)
        )

      IO.binwrite(file, html_patch)
      IO.binwrite(file, diff_header())
      render_diff_body(generator, file, stream)
      IO.binwrite(file, diff_footer())
    end)

    {:ok, path}
  end

  defp diff_header do
    """
    <div id="diff-content">
      <div class="ghd-container">
    """
  end

  defp diff_footer do
    """
      </div>
    </div>
    """
  end

  defp render_diff_body(_generator, file, nil) do
    html_patch = Phoenix.Template.render_to_iodata(__MODULE__, "no_diff", "html", [])
    IO.binwrite(file, html_patch)
  end

  defp render_diff_body(generator, file, stream) do
    Enum.each(stream, fn
      {:ok, patch} ->
        html_patch = Phoenix.Template.render_to_iodata(__MODULE__, "diff", "html", patch: patch)
        IO.binwrite(file, html_patch)

      {:error, error} ->
        Logger.error("Failed to parse diff #{inspect(generator)}: #{inspect(error)}")
        throw({:diff, :invalid_diff})
    end)
  end

  defp tmp_path(prefix) do
    random_string = Base.encode16(:crypto.strong_rand_bytes(4))
    dir = Path.join([Application.get_env(:utility, :gendiff_storage_dir), "rendered"])
    File.mkdir_p(dir)
    Path.join([dir, prefix <> random_string])
  end

  def file_header(patch, status) do
    from = patch.from
    to = patch.to

    case status do
      "changed" -> from
      "renamed" -> "#{from} -> #{to}"
      "removed" -> from
      "added" -> to
    end
  end

  def patch_status(patch) do
    from = patch.from
    to = patch.to

    cond do
      !from -> "added"
      !to -> "removed"
      from == to -> "changed"
      true -> "renamed"
    end
  end

  def line_number(ln) when is_nil(ln), do: ""
  def line_number(ln), do: to_string(ln)

  def line_id(patch, line) do
    hash = :erlang.phash2({patch.from, patch.to})

    ln = "-#{line.from_line_number}-#{line.to_line_number}"

    [to_string(hash), ln]
  end

  def line_type(line), do: to_string(line.type)

  def line_text("+" <> text),
    do: [
      PhoenixHTMLHelpers.Tag.content_tag(:span, "+ ", class: "ghd-line-status"),
      PhoenixHTMLHelpers.Tag.content_tag(:span, text)
    ]

  def line_text("-" <> text),
    do: [
      PhoenixHTMLHelpers.Tag.content_tag(:span, "- ", class: "ghd-line-status"),
      PhoenixHTMLHelpers.Tag.content_tag(:span, text)
    ]

  def line_text(" " <> text),
    do: [
      PhoenixHTMLHelpers.Tag.content_tag(:span, "  ", class: "ghd-line-status"),
      PhoenixHTMLHelpers.Tag.content_tag(:span, text)
    ]

  def line_text(text), do: [PhoenixHTMLHelpers.Tag.content_tag(:span, text)]
end
