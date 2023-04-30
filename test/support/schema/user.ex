defmodule HonuTest.User do
  use Ecto.Schema
  import Ecto.Changeset

  use Honu.Schema

  alias HonuTest.UserAttachment
  alias Honu.Attachments.Attachment

  schema "users" do
    field :username, :string

    has_one_attached(:avatar, UserAttachment)
    has_many_attached(:documents, UserAttachment)

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
        {:documents, &UserAttachment.changeset/2}
      ]
    )
  end
end
