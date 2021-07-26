defmodule Utility.Storage do
  @type generator :: %Utility.GenDiff.Generator{}
  @type html :: Path.t()
  @type id :: String.t()
  @type project :: String.t()

  @callback get(project, id) :: {:ok, html} | {:error, term}
  @callback put(project, id, html) :: :ok | {:error, term}
  @callback list(project) :: list(String.t())
  @callback delete(String.t()) :: :ok

  defp impl(), do: Application.get_env(:utility, :storage)

  def get(generator) do
    get(generator.project, generator.id)
  end

  def get(project, id) do
    impl().get(project, id)
  end

  def delete(file) do
    impl().delete(file)
  end

  def list(project) do
    impl().list(project)
  end

  def put(generator, html) do
    impl().put(generator.project, generator.id, html)
  end
end
