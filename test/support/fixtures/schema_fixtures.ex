defmodule HonuTest.SchemaFixtures do
  alias Honu.Attachments
  alias HonuTest.Book
  alias HonuTest.User
  alias HonuTest.Repo

  def book_fixture(attrs \\ %{}) do
    {:ok, book} =
      attrs
      |> Enum.into(%{
        "title" => "title",
        "pages" => %{
          "0" => %{
            "file" => "test/support/images/elixir.png",
            "page_number" => 1
          },
          "1" => %{
            "file" => "test/support/images/elixir.png",
            "page_number" => 2
          }
        }
      })
      |> create_record_with_attachments(Book)

    book
  end  

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        "username" => "username",
        "avatar" => %{"file" => "test/support/images/elixir.png"},
        "documents" => [
          %{"file" => "test/support/images/elixir.png"},
          %{"file" => "test/support/images/elixir.png"}
        ]
      })
      |> create_record_with_attachments(User)

    user
  end

  defp create_record_with_attachments(attrs, module) do
    case Attachments.attachments_names(attrs, module.attachments()) do
      [] -> raise "Have at least one attachment in attrs."
      attn ->
        Attachments.create_record_with_attachment(
          {module.__struct__(), &module.changeset_with_attachments/2},
          attrs,
          attn
        )
        |> Repo.transaction()
      |> case do
        {:ok, %{record: record}} ->
          record = Enum.reduce(module.attachments(), record, fn att, acc ->
            Repo.preload(acc, [{att, :blob}], force: true)
          end)

          {:ok, record}
        {:error, :record, %Ecto.Changeset{} = changeset, _} -> {:error, changeset}
      end
    end
  end
end
