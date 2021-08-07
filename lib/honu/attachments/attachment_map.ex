defprotocol Honu.Attachments.AttachmentMap do
  @spec build(struct(), String.t()) :: map()
  def build(struct, attachment_name)
end

defimpl Honu.Attachments.AttachmentMap, for: Plug.Upload do
  def build(struct, attachment_name) do
    %{"name" => attachment_name, "blob" => Honu.Attachments.Blob.build(struct)}
  end
end

defimpl Honu.Attachments.AttachmentMap, for: Map do
  def build(%{"file" => file} = attrs, attachment_name) do
    %{
      "name" => attachment_name,
      "blob" => Honu.Attachments.Blob.build(file)
    }
    |> Map.merge(Map.delete(attrs, "file"))
  end

  def build(attrs, attachment_name) do
    Map.merge(%{"name" => attachment_name}, attrs)
  end
end
