defmodule HonuWeb.Router do
  use Plug.Router

  alias HonuWeb.Storage

  plug(:match)
  plug(:dispatch)

  get "/storage/blobs/:signed_blob_id/:filename" do
    {:ok, blob} = Storage.find_signed(signed_blob_id, "blob_id", Storage.permanent_opts())

    conn
    |> put_resp_header("location", Storage.config!(:storage).url(conn, blob))
    |> send_resp(302, "")
  end

  delete "/storage/blobs/:signed_blob_id/:filename" do
    with {:ok, blob} <- Storage.find_signed(signed_blob_id, "blob_id", Storage.permanent_opts()),
         {:ok, _} <- Honu.Attachments.delete_blob(blob, Storage.config!(:repo)) do
      send_resp(conn, 204, "")
    else
      {:error, _} -> send_resp(conn, 404, "Not Found")
    end
  end

  get "/storage/disk/:encoded_key/:filename" do
    with {:ok, %{key: key, disposition: disposition}} <- Storage.decode_verified_key(encoded_key) do
      blob = Honu.Attachments.get_attachment_by_key!(key, Storage.config!(:repo))

      # with {:ok, file} <- Honu.Storage.Disk.read(blob) do
      #  send_resp(conn, 200, file)
      # end
      conn
      |> put_resp_header("content-type", blob.content_type)
      |> put_resp_header(
        "content-disposition",
        Storage.Disk.blob_content_disposition(blob, disposition)
      )
      |> send_file(200, Honu.Storage.Disk.path_for(blob.key))
    else
      {:error, _msg} -> send_resp(conn, 404, "Not Found")
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
