defmodule Honu.AttachmentsTest do
  use HonuTest.DataCase

  alias Honu.Attachments
  alias HonuTest.Book
  alias HonuTest.User

  test "compute_checksum_in_chunks/1" do
    checksum = Attachments.compute_checksum_in_chunks("test/support/images/elixir.png")
    assert checksum == "630523f18b6f5b4d56fa3e1b3510c2ac"
  end

  describe "attachment" do
    test "create_record_with_attachment/3 with has_one and file map" do
      attrs = %{
        "username" => "username",
        "avatar" => %{"file" => "test/support/images/elixir.png"}
      }

      result = Attachments.create_record_with_attachment(
        {%User{}, &User.changeset_with_attachments/2},
        attrs,
        Attachments.attachments_names(attrs, User.attachments())
      )
      |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      assert user.username == "username"
      assert_blob user.avatar.blob
    end

    test "create_record_with_attachment/3 with has_one and Plug.Upload" do
      attrs = %{
        "username" => "username",
        "avatar" => %Plug.Upload{
          path: "test/support/images/elixir.png",
          content_type: "image/png",
          filename: "elixir.png"
        }
      }

      result = Attachments.create_record_with_attachment(
        {%User{}, &User.changeset_with_attachments/2},
        attrs,
        Attachments.attachments_names(attrs, User.attachments())
      )
      |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      assert user.username == "username"
      assert_blob user.avatar.blob
    end

    test "create_record_with_attachment/3 with has_many and Plug.Upload" do
      attrs = %{
        "username" => "username",
        "documents" => [
          %Plug.Upload{
            path: "test/support/images/elixir.png",
            content_type: "image/png",
            filename: "elixir.png"
          },
          %Plug.Upload{
            path: "test/support/images/elixir.png",
            content_type: "image/png",
            filename: "elixir.png"
          }
        ]
      }

      result = Attachments.create_record_with_attachment(
        {%User{}, &User.changeset_with_attachments/2},
        attrs,
        Attachments.attachments_names(attrs, User.attachments())
      )
      |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      assert user.username == "username"
      for document <- user.documents do
        assert_blob document.blob
      end
    end

    test "create_record_with_attachment/3 with has_many and extra attribute in attachment" do
      attrs = %{
        "title" => "title",
        "pages" => %{
          "0" => %{
            "file" => %Plug.Upload{
              path: "test/support/images/elixir.png",
              content_type: "image/png",
              filename: "elixir.png"
            },
            "page_number" => 1
          },
          "1" => %{
            "file" => %Plug.Upload{
              path: "test/support/images/elixir.png",
              content_type: "image/png",
              filename: "elixir.png"
            },
            "page_number" => 2
          }
        }
      }

      result = Attachments.create_record_with_attachment(
        {%Book{}, &Book.changeset_with_attachments/2},
        attrs,
        Attachments.attachments_names(attrs, Book.attachments())
      )
      |> Repo.transaction()

      assert {:ok, %{record: %Book{} = book}} = result
      assert book.title == "title"
      for page <- book.pages do
        assert_blob page.blob
      end
    end
  end
end
