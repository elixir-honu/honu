defmodule Honu.Storage.S3 do
  require Logger

  alias Honu.Attachments.Blob
  alias Honu.Storage

  @behaviour Storage

  @impl true
  def delete(blob = %Blob{}, opts \\ []) do
    ensure_aws_loaded!()

    AWS.S3.delete_object(
      client(),
      Storage.config!(:s3_bucket, opts),
      path_for(blob.key, opts),
      %{}
    )
    |> handle_delete()
  end

  @impl true
  def exists?(blob_or_key, opts \\ [])

  @impl true
  def exists?(blob = %Blob{}, opts) do
    exists?(blob.key, opts)
  end

  @impl true
  def exists?(key, opts) when is_binary(key) do
    ensure_aws_loaded!()

    AWS.S3.get_object(
      client(),
      Storage.config!(:s3_bucket, opts),
      path_for(key, opts)
    )
    |> handle_exists()
  end

  @impl true
  def put(blob = %Blob{}, opts \\ []) do
    ensure_aws_loaded!()
    {:ok, contents} = Honu.Upload.contents(blob.path)

    AWS.S3.put_object(
      client(),
      Storage.config!(:s3_bucket, opts),
      path_for(blob.key, opts),
      %{"Body" => contents, "ContentMD5" => content_md5(blob), "ContentType" => blob.content_type}
    )
    |> handle_put(blob)
  end

  @impl true
  def read(blob = %Blob{}, opts \\ []) do
    ensure_aws_loaded!()

    AWS.S3.get_object(
      client(),
      Storage.config!(:s3_bucket, opts),
      path_for(blob.key, opts)
    )
    |> handle_read(blob)
  end

  def client do
    case Storage.config(:s3_client) do
      {:ok, module} ->
        module.client()

      :error ->
        AWS.Client.create(
          Storage.config!(:s3_access_key_id),
          Storage.config!(:s3_secret_access_key),
          Storage.config!(:s3_region)
        )
        |> maybe_put_endpoint()
    end
  end

  def path_for(key, opts) do
    case Storage.config(:s3_root_dir, opts) do
      {:ok, dir} -> Path.join([dir, opts[:prefix] || "", key])
      :error -> Path.join(opts[:prefix] || "", key)
    end
  end

  defp handle_delete({:error, error}), do: handle_error(error)

  defp handle_delete({:ok, _, %{status_code: 204}}) do
    :ok
  end

  defp handle_exists({:ok, _, %{status_code: 200}}), do: true
  defp handle_exists({:error, {_error_atom, %{status_code: 404}}}), do: false
  defp handle_exists({:error, error}), do: handle_error(error)

  defp handle_put({:error, error}, _blob), do: handle_error(error)

  defp handle_put({:ok, _, %{status_code: 200}}, blob) do
    {:ok, blob}
  end

  defp handle_read({:error, error}, _blob), do: handle_error(error)

  defp handle_read({:ok, _, %{status_code: 200, body: contents} = request}, blob) do
    etag =
      request.headers
      |> get_resp_header("etag")
      |> String.trim("\"")

    if etag == blob.checksum do
      {:ok, contents}
    else
      handle_error("ETag #{etag} doesn't match blob checksum #{blob.checksum}")
    end
  end

  defp handle_error(error), do: {:error, "S3 error: #{inspect(error)}"}

  defp get_resp_header(headers, key) do
    headers
    |> List.keyfind(key, 0)
    |> elem(1)
  end

  defp maybe_put_endpoint(client) do
    case Storage.config(:s3_endpoint) do
      {:ok, endpoint} -> AWS.Client.put_endpoint(client, endpoint)
      :error -> client
    end
  end

  defp content_md5(blob) do
    blob.checksum
    |> Base.decode16!(case: :lower)
    |> Base.encode64()
  end

  defp ensure_aws_loaded!() do
    unless Code.ensure_loaded?(AWS) do
      Logger.error("""
      Could not find aws dependency.
      Please add :aws to your dependencies:
          {:aws, "~> 0.11"}
      """)

      raise "missing aws dependency"
    end
  end
end
