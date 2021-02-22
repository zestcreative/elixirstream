defmodule UtilityWeb.GenDiffView do
  use UtilityWeb, :view
  require Logger

  def render_diff(stream, generator) do
    path = tmp_path("html-#{generator.project}-#{generator.id}-")

    File.open!(path, [:write, :raw, :binary, :write_delay], fn file ->
      html_patch =
        Phoenix.View.render_to_iodata(__MODULE__, "diff_header.html", generator: generator)

      IO.binwrite(file, html_patch)
      render_diff_body(generator, file, stream)
      html_patch = Phoenix.View.render_to_iodata(__MODULE__, "diff_footer.html", [])
      IO.binwrite(file, html_patch)
    end)

    {:ok, path}
  end

  defp render_diff_body(_generator, file, nil) do
    html_patch = Phoenix.View.render_to_iodata(__MODULE__, "no_diff.html", [])
    IO.binwrite(file, html_patch)
  end

  defp render_diff_body(generator, file, stream) do
    Enum.each(stream, fn
      {:ok, patch} ->
        html_patch = Phoenix.View.render_to_iodata(__MODULE__, "diff.html", patch: patch)
        IO.binwrite(file, html_patch)

      {:error, error} ->
        Logger.error("Failed to parse diff #{inspect(generator)}: #{inspect(error)}")
        throw({:diff, :invalid_diff})
    end)
  end

  defp tmp_path(prefix) do
    random_string = Base.encode16(:crypto.strong_rand_bytes(4))
    Path.join([System.tmp_dir!(), "utility", prefix <> random_string])
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
    do: [content_tag(:span, "+ ", class: "ghd-line-status"), content_tag(:span, text)]

  def line_text("-" <> text),
    do: [content_tag(:span, "- ", class: "ghd-line-status"), content_tag(:span, text)]

  def line_text(" " <> text),
    do: [content_tag(:span, "  ", class: "ghd-line-status"), content_tag(:span, text)]

  def line_text(text), do: [content_tag(:span, text)]
end
