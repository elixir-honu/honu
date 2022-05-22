defmodule Honu.Attachments.Attachment do
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Honu.Attachments.AttachmentMap
  alias Honu.Attachments.Blob

  def attachments_changeset(changeset, attrs, attachments_names) do
    # TODO: Support both atom and string in map
    #       Currently only string keys are supported
    Enum.reduce(attachments_names, changeset, fn {name, func}, cset ->
      attachment_changeset(cset, attrs, {to_string(name), func})
    end)
  end

  defp attachment_changeset(changeset, attrs, {attachment_name, changeset_func})
       when is_function(changeset_func, 2) do
    if upload = attrs[attachment_name] do
      attachments = AttachmentMap.build(upload, attachment_name)

      changeset
      |> cast(Map.put(attrs, attachment_name, attachments), [])
      |> cast_assoc(String.to_atom(attachment_name), with: changeset_func)
      |> prepare_changes(fn changeset ->
        blob_ids = get_blob_ids(changeset, String.to_atom(attachment_name))
        query = from(b in Blob, where: b.id in ^blob_ids)
        changeset.repo.update_all(query, set: [deleted_at: NaiveDateTime.utc_now()])

        changeset
      end)
    else
      changeset
    end
  end

  defp get_blob_ids(changeset, attachment_name) do
    case get_change(changeset, attachment_name) do
      changes when is_list(changes) ->
        changes
        |> Enum.filter(&(&1.action == :replace))
        |> Enum.map(&(&1.data.blob_id))
      _change ->
        changeset.data
        |> Map.get(attachment_name)
        |> Map.get(:blob_id)
        |> then(&[&1])
    end
  end
end
