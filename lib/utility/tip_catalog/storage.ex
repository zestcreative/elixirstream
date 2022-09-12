defmodule Utility.TipCatalog.Storage do
  @callback download(Path.t(), Path.t(), Keyword.t()) :: {:ok, Path.t()} | {:error, term}
  @callback url(Path.t(), Keyword.t()) :: {:ok, String.t()} | {:error, term}
  @callback upload(Path.t(), Path.t(), Keyword.t()) :: {:ok, map()} | {:error, term}

  defp impl(), do: Application.get_env(:utility, :tip_storage)

  def download(remote_path, local_path, opts \\ []) do
    impl().download(remote_path, local_path, opts)
  end

  def upload(local_file, remote_path, opts \\ []) do
    impl().upload(local_file, remote_path, opts)
  end

  def url(remote_path, opts \\ []) do
    impl().url(remote_path, opts)
  end
end
