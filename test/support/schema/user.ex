defmodule HonuTest.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias HonuTest.UserAttachment
  alias Honu.Attachments.Attachment

  schema "users" do
    field :username, :string

    has_one :avatar, UserAttachment,
      foreign_key: :record_id,
      where: [name: "avatar"],
      on_replace: :delete_if_exists

    has_many :documents, UserAttachment,
      foreign_key: :record_id,
      where: [name: "documents"],
      on_replace: :delete_if_exists

    timestamps()
  end

  def attachments do
    [:avatar, :documents]
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_required([:username])
  end

  def changeset_with_attachments(user, attrs) do
    user
    |> changeset(attrs)
    |> Attachment.attachments_changeset(
      attrs,
      [
        {:avatar, &UserAttachment.changeset/2},
        {:documents, &UserAttachment.changeset/2},
      ]
    )
  end
end
