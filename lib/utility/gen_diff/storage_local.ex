defmodule Utility.GenDiff.StorageLocal do
  @moduledoc false
  @behaviour Utility.GenDiff.Storage

  def list(project, term) do
    [dir(), project, term]
    |> Path.join()
    |> Path.wildcard()
  end

  def delete(file) do
    File.rm(file)
  end

  # Rendered HTML for the chunked web view — streamed.
  def get(project, id) do
    path = path_for(project, id, "html")

    if File.regular?(path) do
      {:ok, File.stream!(path, [:read_ahead])}
    else
      {:error, :not_found}
    end
  end

  def put(project, id, file_path), do: copy(file_path, path_for(project, id, "html"))

  # Raw (path-cleaned) git patch — read whole for the Markdown API.
  def get_patch(project, id), do: read(path_for(project, id, "patch"))
  def put_patch(project, id, file_path), do: copy(file_path, path_for(project, id, "patch"))

  # Assembled Markdown document — cached so repeat requests skip re-assembly.
  def get_md(project, id), do: read(path_for(project, id, "md"))
  def put_md(project, id, content), do: write(content, path_for(project, id, "md"))

  defp read(path) do
    if File.regular?(path), do: {:ok, File.read!(path)}, else: {:error, :not_found}
  end

  defp copy(src, dest) do
    File.mkdir_p!(Path.dirname(dest))
    File.cp!(src, dest)
    :ok
  end

  defp write(content, dest) do
    File.mkdir_p!(Path.dirname(dest))
    File.write!(dest, content)
    :ok
  end

  defp path_for(project, id, ext) do
    hash = :erlang.phash2({Application.get_env(:utility, :cache_version), id})
    Path.join([dir(), project, "#{project}-#{id}-#{hash}.#{ext}"])
  end

  defp dir() do
    Path.join(Application.get_env(:utility, :gendiff_storage_dir), "diff-html")
  end
end
