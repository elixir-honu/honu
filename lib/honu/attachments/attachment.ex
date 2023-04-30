defmodule Honu.Attachments.Attachment do
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Honu.Attachments.AttachmentMap
  alias Honu.Attachments.Blob

  def attachments_changeset(changeset, attrs, attachments_names)
      when is_list(attachments_names) do
    if convert?(attrs) do
      Enum.reduce(attachments_names, changeset, fn {name, func}, cset ->
        attachment_changeset(cset, attrs, {name, func})
      end)
    else
      Enum.reduce(attachments_names, changeset, fn {name, func}, cset ->
        attachment_changeset(cset, attrs, {Atom.to_string(name), func})
      end)
    end
  end

  defp attachment_changeset(changeset, attrs, {attachment_name, changeset_func})
       when is_function(changeset_func, 2) do
    if upload = attrs[attachment_name] do
      attachments = AttachmentMap.build(upload, attachment_name)

      changeset
      |> cast(Map.put(attrs, attachment_name, attachments), [])
      |> cast_assoc(attachment_name |> to_string() |> String.to_existing_atom(),
        with: changeset_func
      )
      |> prepare_changes(fn changeset ->
        attachment_name =
          attachment_name
          |> to_string()
          |> String.to_existing_atom()

        blob_ids = get_blob_ids(changeset, attachment_name)
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
        |> Enum.map(& &1.data.blob_id)

      nil ->
        []

      _change ->
        get_has_one_blob_id(changeset, attachment_name)
    end
  end

  defp get_has_one_blob_id(changeset, attachment_name) do
    case Map.get(changeset.data, attachment_name) do
      nil -> []
      %Ecto.Association.NotLoaded{} -> []
      attachment -> [attachment.blob_id]
    end
  end

  defp convert?(attrs) do
    attrs
    |> Map.keys()
    |> List.first()
    |> is_atom()
  end
end
