defmodule UtilityWeb.GenDiffView do
  use UtilityWeb, :view
  require Logger

  def render_diff(stream, generator) do
    path = tmp_path("html-#{generator.project}-#{generator.id}-")

    File.open!(path, [:write, :raw, :binary, :write_delay], fn file ->
      html_patch = Phoenix.View.render_to_iodata(__MODULE__, "diff_header.html", generator: generator)
      IO.binwrite(file, html_patch)

      if stream do
        Enum.each(stream, fn
          {:ok, patch} ->
            html_patch = Phoenix.View.render_to_iodata(__MODULE__, "diff.html", patch: patch)
            IO.binwrite(file, html_patch)

          {:error, error} ->
            Logger.error("Failed to parse diff #{inspect(generator)}: #{inspect(error)}")
            throw({:diff, :invalid_diff})
        end)
      else
        html_patch = Phoenix.View.render_to_iodata(__MODULE__, "no_diff.html", [])
        IO.binwrite(file, html_patch)
      end

      html_patch = Phoenix.View.render_to_iodata(__MODULE__, "diff_footer.html", [])
      IO.binwrite(file, html_patch)
    end)

    {:ok, path}
  end

  def parse_versions(input) do
    with {:ok, [from, to]} <- versions_from_input(input),
         {:ok, from} <- parse_version(from),
         {:ok, to} <- parse_version(to) do
      {:ok, from, to}
    else
      _ ->
        :error
    end
  end

  def versions_from_input(input) when is_binary(input) do
    input
    |> String.split("..")
    |> case do
      [from, to] ->
        {:ok, Enum.map([from, to], &String.trim/1)}

      [_from] ->
        :error
    end
  end

  def versions_from_input(_), do: :error

  def parse_version(input), do: Version.parse(input)

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

  def line_text("+" <> text), do: "+ " <> text
  def line_text("-" <> text), do: "- " <> text
  def line_text(text), do: " " <> text
end
