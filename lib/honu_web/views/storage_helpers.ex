defmodule HonuWeb.StorageHelpers do
  alias Honu.Attachments.Blob
  alias HonuWeb.Storage

  # Permanent url
  def blob_url(conn, blob = %Blob{}, _disposition \\ "inline") do
    data = Storage.generate_data(blob.key, Storage.permanent_opts())

    Storage.base_url(conn)
    |> URI.merge(path(blob, data))
    |> to_string()
  end

  defp path(blob, data) do
    "/#{Storage.namespace()}/storage/blobs/#{data}--#{Storage.generate_digest(data)}/#{Storage.sanitized_filename(blob.filename)}"
  end
end
