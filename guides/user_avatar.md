# User avatar

Starting from a user schema module it is possible to add an avatar image to each user.

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string

    timestamps()
  end
end
```

To do so, first the creation of the attachments table for the above User module is needed.

```bash
mix ecto.gen.migration create_user_attachments
```

```elixir
defmodule MyApp.Repo.Migrations.CreateUserAttachments do
  use Ecto.Migration
  require Honu.Migration

  def change do
    Honu.Migration.create_attachments_table(MyApp.Accounts.User)
  end
end
```

After creating the intermediary table, it's time to create the module that will represent it.

```elixir
defmodule MyApp.Attachments.UserAttachment do
  use Ecto.Schema
  import Ecto.Changeset
  alias Honu.Attachments.Blob
  alias MyApp.Accounts.User

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
```

In order to guarantee referential integrity, an intermediary table for each module is created.
It is also possible to leverage this to introduce more attributes in the intermediary table, without having to create a new representation.

Having created the intermediary table, it is now possible to add the attachment attributes to the initial user schema.

For this example, a user only was one avatar.

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias MyApp.Attachments.UserAttachment
  alias Honu.Attachments.Attachment

  schema "users" do
    field :username, :string

    has_one :avatar, UserAttachment,
      foreign_key: :record_id,
      where: [name: "avatar"]

    timestamps()
  end

  def attachments do
    [:avatar]
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
    |> Attachment.attachments_changeset(attrs, [{:avatar, &UserAttachment.changeset/2}])
  end
end
```

Finally it's possible to create a user with an avatar with the following function.

```elixir
def create_user_with_attachments(attrs \\ %{}) do
  case Attachments.attachments_names(attrs, User.attachments()) do
    attn when attn == [] -> create_user(attrs)
    attn when attn != [] ->
      Attachments.create_record_with_attachment(
        {%User{}, &User.changeset_with_attachments/2},
        attrs,
        attn
      )
      |> Repo.transaction()
  end
end
```

```elixir
{:ok, user} = MyApp.Accounts.create_user_with_attachments(%{
  "username" => "user123",
  "avatar" => %{"file" => "/path/to/image"}
})
```

It's also possible to create a user with an avatar in a form:

```elixir
<.form let={f} for={@changeset} action={@action} multipart>
  <%= if @changeset.action do %>
    <div class="alert alert-danger">
      <p>Oops, something went wrong! Please check the errors below.</p>
    </div>
  <% end %>

  <%= label f, :username %>
  <%= text_input f, :username %>
  <%= error_tag f, :username %>

  <%= label f, :avatar %>
  <%= file_input f, :avatar %>
  <%= error_tag f, :avatar %>

  <div>
    <%= submit "Save" %>
  </div>
</.form>
```

And if the /honu scope is being used, it's also possible to show it's avatar with the included helper function as long as the avatar and it's corresponding blob are preloaded.

```elixir
<h1>Show User</h1>

<ul>

  <li>
    <strong>Username:</strong>
    <%= @user.username %>
  </li>

  <li>
    <strong>Avatar:</strong>
    <%= if @user.avatar do %>
      <%= img_tag(HonuWeb.StorageHelpers.blob_url(@conn, @user.avatar.blob)) %>
    <% end %>
  </li>

</ul>

<span><%= link "Edit", to: Routes.user_path(@conn, :edit, @user) %></span> |
<span><%= link "Back", to: Routes.user_path(@conn, :index) %></span>
```
