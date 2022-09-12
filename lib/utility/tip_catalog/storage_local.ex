defmodule Utility.TipCatalog.StorageLocal do
  @behaviour Utility.TipCatalog.Storage
  @bucket Application.compile_env(:utility, Utility.TipCatalog.Storage)[:bucket]

  def url(key, _opts \\ []) do
    path = Path.join(["uploads", @bucket, key])

    if File.regular?(path) do
      {:ok, "/" <> path}
    else
      {:error, :not_found}
    end
  end

  def download(remote_path, local_path, _opts \\ []) do
    remote = Path.join([@bucket, remote_path])
    File.cp!(remote, local_path)
    {:ok, local_path}
  end

  def upload(file_path, destination_path, _opts \\ []) do
    destination = Path.join(["uploads", @bucket, destination_path])
    File.mkdir_p!(Path.dirname(destination))
    File.cp!(file_path, destination)

    {:ok,
     %{
       body: %{
         bucket: @bucket,
         key: destination_path,
         location: Path.join(["uploads", @bucket, destination_path])
       }
     }}
  end
end
