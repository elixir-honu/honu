defprotocol Honu.Attachments.AttachmentMap do
  @spec build(struct(), String.t()) :: map()
  def build(struct, attachment_name)
end

defimpl Honu.Attachments.AttachmentMap, for: Plug.Upload do
  def build(struct, attachment_name) do
    %{"name" => attachment_name, "blob" => Honu.Attachments.Blob.build(struct)}
  end
end

defimpl Honu.Attachments.AttachmentMap, for: List do
  def build(struct, attachment_name) do
    Enum.reduce(struct, [], fn attachment, l ->
      [@protocol.build(attachment, attachment_name) | l]
    end)
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

  def build(%{"0" => map} = attrs, attachment_name) when is_map(map) do
    Enum.reduce(attrs, %{}, fn attachment, acc ->
      attachment
      |> build_one_with_index(attachment_name)
      |> Map.merge(acc)
    end)
  end

  def build(attrs, attachment_name) do
    Map.merge(%{"name" => attachment_name}, attrs)
  end

  defp build_one_with_index({id, attrs}, attachment_name) when is_map(attrs) do
    attrs
    |> @protocol.build(attachment_name)
    |> then(&Map.put(%{}, id, &1))
  end
end
