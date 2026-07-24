defmodule Utility.GenDiff.Storage do
  @moduledoc false
  @type generator :: %Utility.GenDiff.Generator{}
  @type html :: Path.t()
  @type id :: String.t()
  @type project :: String.t()

  @callback get(project, id) :: {:ok, html} | {:error, term}
  @callback put(project, id, html) :: :ok | {:error, term}
  @callback get_patch(project, id) :: {:ok, binary} | {:error, term}
  @callback put_patch(project, id, Path.t()) :: :ok | {:error, term}
  @callback get_md(project, id) :: {:ok, binary} | {:error, term}
  @callback put_md(project, id, binary) :: :ok | {:error, term}
  @callback list(project, term) :: list(String.t())
  @callback delete(String.t()) :: :ok

  defp impl(), do: Application.get_env(:utility, :gendiff_storage)

  def get(generator) do
    get(generator.project, generator.id)
  end

  def get(project, id) do
    impl().get(project, id)
  end

  def delete(file) do
    impl().delete(file)
  end

  def list(project, term) do
    impl().list(project, term)
  end

  def put(generator, html) do
    impl().put(generator.project, generator.id, html)
  end

  def get_patch(generator), do: impl().get_patch(generator.project, generator.id)

  def put_patch(generator, file_path),
    do: impl().put_patch(generator.project, generator.id, file_path)

  def get_md(generator), do: impl().get_md(generator.project, generator.id)
  def put_md(generator, content), do: impl().put_md(generator.project, generator.id, content)
end
