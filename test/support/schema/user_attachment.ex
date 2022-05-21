defmodule HonuTest.UserAttachment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Honu.Attachments.Blob
  alias HonuTest.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "honu_user_attachments" do
    field :name, :string
    belongs_to :blob, Blob
    belongs_to :record, User, type: :integer

    timestamps()
  end

  @doc false
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> cast_assoc(:blob, required: true, with: &Blob.changeset/2)
  end
end
