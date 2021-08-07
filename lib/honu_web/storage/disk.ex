defmodule HonuWeb.Storage.Disk do
  alias Honu.Attachments.Blob
  alias HonuWeb.Storage

  @behaviour Storage

  @impl true
  def url(conn, blob = %Blob{}, opts \\ []) do
    data =
      Storage.generate_data(%{
        key: blob.key,
        disposition: Storage.content_disposition_with(blob.filename, opts[:disposition])
        # content_type: content_type
        # service_name: name
      })

    Storage.base_url(conn)
    |> URI.merge(path(blob, data))
    |> URI.merge(blob_query(blob, opts))
    |> to_string
  end

  def blob_content_disposition(blob, %{disposition: disposition, filename: filename}) do
    "#{disposition}; filename=\"#{filename}\"; filename*=UTF-8''#{blob.filename}"
  end

  defp path(blob, data) do
    "/#{Storage.namespace()}/storage/disk/#{data}--#{Storage.generate_digest(data)}/#{Storage.sanitized_filename(blob.filename)}"
  end

  defp blob_query(blob, opts) do
    map = Storage.content_disposition_with(blob.filename, opts[:disposition])

    URI.encode_query(%{
      "content_type" => blob.content_type,
      "disposition" => blob_content_disposition(blob, map)
    })
    |> (&"?#{&1}").()
  end
end
