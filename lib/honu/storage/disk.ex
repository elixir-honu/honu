defmodule Honu.Storage.Disk do
  alias Honu.Attachments.Blob
  alias Honu.Storage

  @behaviour Storage

  # If using the path from Plug.Upload, it is only available during the request
  # as Plug will remove it once the request completes
  # https://hexdocs.pm/phoenix/1.3.0-rc.2/file_uploads.html
  @impl true
  def put(blob = %Blob{}, opts \\ []) do
    make_path_for(blob.key, opts)

    if File.exists?(path_for(blob.key, opts)) || opts[:force] do
      {:error, "File already exists at upload destination"}
    else
      File.cp!(blob.path, path_for(blob.key, opts))
      {:ok, blob}
    end
  end

  @impl true
  def delete(blob = %Blob{}, opts \\ []) do
    path_for(blob.key, opts)
    |> File.rm()
    |> case do
      :ok ->
        # TODO: Remove empty dir here?
        # recursive File.rmdir(String.replace_trailing(path_for(blob.key, opts), blob.key, ""))
        :ok

      {:error, error} ->
        {:error, "Could not remove file: #{error}"}
    end
  end

  @impl true
  def read(blob = %Blob{}, opts \\ []) do
    path_for(blob.key, opts)
    |> File.read()
  end

  @impl true
  def exists?(blob_or_key, opts \\ [])

  @impl true
  def exists?(blob = %Blob{}, opts) do
    exists?(blob.key, opts)
  end

  @impl true
  def exists?(key, opts) when is_binary(key) do
    File.exists?(path_for(key, opts))
  end

  def path_for(key, opts \\ []) do
    Path.join([Storage.config!(:root_dir, opts), opts[:prefix] || "", folder_for(key), key])
  end

  defp make_path_for(key, opts) do
    path_for(key, opts)
    |> Path.dirname()
    |> File.mkdir_p!()
  end

  defp folder_for(key) do
    "#{String.slice(key, 0..1)}/#{String.slice(key, 2..3)}"
  end
end
