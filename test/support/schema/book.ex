defmodule HonuTest.Book do
  use Ecto.Schema
  import Ecto.Changeset

  use Honu.Schema

  alias HonuTest.BookAttachment
  alias Honu.Attachments.Attachment

  schema "books" do
    field :title, :string

    has_many_attached :pages, BookAttachment,
      preload_order: [asc: :page_number]

    timestamps()
  end

  def attachments do
    [:pages]
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end

  def changeset_with_attachments(book, attrs) do
    book
    |> changeset(attrs)
    |> Attachment.attachments_changeset(attrs, [{:pages, &BookAttachment.changeset/2}])
  end
end
