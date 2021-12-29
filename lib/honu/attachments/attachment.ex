defmodule Honu.Attachments.Attachment do
  import Ecto.Changeset

  alias Honu.Attachments.AttachmentMap

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
      attachments = attachments_attrs(attachment_name, upload)

      changeset
      |> cast(Map.put(attrs, attachment_name, attachments), [])
      |> cast_assoc(String.to_atom(attachment_name), with: changeset_func)
    else
      changeset
    end
  end

  defp attachments_attrs(attachment_name, attachments) when is_list(attachments) do
    Enum.reduce(attachments, [], fn upload, l ->
      # upload :: Plug.Upload.t() | map()
      [AttachmentMap.build(upload, attachment_name) | l]
    end)
  end

  defp attachments_attrs(attachment_name, attachment) when is_map(attachment) do
    AttachmentMap.build(attachment, attachment_name)
    # Enum.reduce(Map.keys(attachments), %{}, fn key, m ->
    #  # upload :: Plug.Upload.t() | map()
    #  upload = attachments[key]
    #  Map.merge(m, %{key => AttachmentMap.build(upload, attachment_name)})
    # end)
  end
end
