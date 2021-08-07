defmodule Honu.Attachments.Blob do
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{
          key: String.t(),
          filename: String.t(),
          content_type: String.t(),
          metadata: map() | nil,
          byte_size: non_neg_integer(),
          checksum: String.t(),
          deleted_at: NaiveDateTime.t(),
          path: String.t(),
          inserted_at: NaiveDateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "honu_blobs" do
    field :key, :string
    field :filename, :string
    field :content_type, :string
    field :metadata, :map
    field :byte_size, :integer
    field :checksum, :string
    field :deleted_at, :naive_datetime
    field :path, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(blob, attrs) do
    blob
    |> cast(attrs, [
      :key,
      :filename,
      :byte_size,
      :checksum,
      :content_type,
      :metadata,
      :deleted_at,
      :path
    ])
    |> validate_required([:key, :filename, :byte_size, :checksum])
    |> unique_constraint(:key)
  end

  def build(attrs) do
    %{
      key: Honu.SecureRandom.base36(28),
      filename: Honu.Upload.filename(attrs),
      byte_size: File.stat!(Honu.Upload.path(attrs)).size,
      checksum: Honu.Attachments.compute_checksum_in_chunks(Honu.Upload.path(attrs)),
      content_type: Honu.Upload.content_type(attrs),
      path: Honu.Upload.path(attrs)
    }
  end
end
