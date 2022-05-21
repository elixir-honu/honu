defmodule HonuTest.BookAttachment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Honu.Attachments.Blob
  alias HonuTest.Book

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "honu_book_attachments" do
    field :name, :string
    belongs_to :blob, Blob
    belongs_to :record, Book, type: :integer

    field :page_number, :integer

    timestamps()
  end

  @doc false
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:name, :page_number])
    |> validate_required([:name, :page_number])
    |> unique_constraint([:record_id, :page_number])
    |> cast_assoc(:blob, required: true, with: &Blob.changeset/2)
  end
end
