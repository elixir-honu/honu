defmodule Honu.Attachments do
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Honu.Storage
  alias Honu.Attachments.Blob

  def get_attachment_by_key!(key, repo) do
    repo.get_by!(Blob, key: key)
  end

  def delete_blob(%Blob{} = blob, repo) do
    Multi.new()
    |> Multi.delete(:record, blob)
    |> Multi.run(:delete_file, fn _repo, %{record: record} ->
      case Storage.config(:storage).delete(record) do
        :ok -> {:ok, record}
        {:error, _} -> {:error, record}
      end
    end)
    |> repo.transaction()
  end

  def compute_checksum_in_chunks(path) do
    File.stream!(path, [], 5120)
    |> Enum.reduce(:crypto.hash_init(:md5), fn line, acc ->
      :crypto.hash_update(acc, line)
    end)
    |> :crypto.hash_final()
    |> Base.encode16(case: :lower)
  end

  def create_record_with_attachment({record, changeset_func}, attrs, attachments_names)
      when is_function(changeset_func, 2) do
    Multi.new()
    |> Multi.insert(:record, changeset_func.(record, attrs))
    |> upload_blobs(attachments_names)
  end

  # Only replace
  def update_record_with_attachment({record, changeset_func}, attrs, attachments_names)
      when is_function(changeset_func, 2) do
    mark_attachments_for_deletion(record, attachments_names)
    |> Multi.prepend(Multi.update(Multi.new(), :record, changeset_func.(record, attrs)))
    |> upload_blobs(attachments_names)
  end

  def delete_record_with_attachment(record, attachments_names) do
    mark_attachments_for_deletion(record, attachments_names)
    |> Multi.prepend(Multi.delete(Multi.new(), :record, record))
  end

  defp upload_blobs(multi, attachments_names) do
    Multi.run(multi, :upload, fn _repo, %{record: record} ->
      # TODO: stop when first put file fails instead of uploading all and then
      #       deleting all
      Enum.map(attachments_names, fn attachment_name ->
        case Map.get(record, attachment_name) do
          att when is_list(att) -> Enum.map(att, fn x -> Storage.config(:storage).put(x.blob) end)
          att -> Storage.config(:storage).put(att.blob)
        end
      end)
      |> List.flatten()
      # [{:ok, blob} | {:error, reason}]
      |> (fn list ->
            Enum.find(list, fn x -> elem(x, 0) == :error end)
            |> case do
              {:error, _} ->
                # TODO:
                # Delete files from Storage, async
                # Enum.each(&1, fn x -> AsyncStorage.delete(x) end)
                Enum.filter(list, fn x -> elem(x, 0) == :error end)
                |> Enum.each(fn x -> Storage.config(:storage).delete(x) end)

                {:error, record}

              nil ->
                {:ok, record}
            end
          end).()
    end)
  end

  defp mark_attachments_for_deletion(record, attachments_names) do
    Enum.reduce(attachments_names, Multi.new(), fn name, multi ->
      Multi.update_all(
        multi,
        {:blob, name},
        get_blobs_query(record, name),
        set: [deleted_at: NaiveDateTime.utc_now()]
      )
    end)
  end

  defp get_blobs_query(record, attachment_name) do
    attachment =
      case Map.get(record, attachment_name) do
        att when is_list(att) -> Enum.map(att, fn x -> x.blob_id end)
        att -> att.blob_id
      end

    from(
      b in Blob,
      where: b.id in ^attachment,
      select: b
    )
  end
end
