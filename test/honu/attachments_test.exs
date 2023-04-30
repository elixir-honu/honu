defmodule Honu.AttachmentsTest do
  use HonuTest.DataCase

  alias Honu.Attachments
  alias HonuTest.Book
  alias HonuTest.User

  test "attached?/1" do
    import HonuTest.SchemaFixtures

    user = user_fixture()
    refute Honu.Attachments.attached?(user.avatar)
    refute Honu.Attachments.attached?(user.documents)

    refute Honu.Attachments.attached?(Map.put(user, :avatar, nil))
    refute Honu.Attachments.attached?(Map.put(user, :documents, []))

    user_with_attachments = user_fixture([:avatar, :documents])
    assert Honu.Attachments.attached?(user_with_attachments.avatar)
    assert Honu.Attachments.attached?(user_with_attachments.documents)
  end

  test "compute_checksum_in_chunks/1" do
    checksum = Attachments.compute_checksum_in_chunks("test/support/images/elixir.png")
    assert checksum == "630523f18b6f5b4d56fa3e1b3510c2ac"
  end

  describe "attachment" do
    import HonuTest.SchemaFixtures

    test "create_record_with_attachment/3 with has_one and file map" do
      attrs = %{
        "username" => "username",
        "avatar" => %{"file" => "test/support/images/elixir.png"}
      }

      result =
        Attachments.create_record_with_attachment(
          {%User{}, &User.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, User.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      assert user.username == "username"
      assert_blob(user.avatar.blob)
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

      result =
        Attachments.create_record_with_attachment(
          {%User{}, &User.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, User.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      assert user.username == "username"
      assert_blob(user.avatar.blob)
    end

    test "create_record_with_attachment/3 with has_many and file map" do
      attrs = %{
        "username" => "username",
        "documents" => [
          %{"file" => "test/support/images/elixir.png"},
          %{"file" => "test/support/images/elixir.png"}
        ]
      }

      result =
        Attachments.create_record_with_attachment(
          {%User{}, &User.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, User.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      assert user.username == "username"
      assert length(user.documents) == 2

      for document <- user.documents do
        assert_blob(document.blob)
      end
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

      result =
        Attachments.create_record_with_attachment(
          {%User{}, &User.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, User.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      assert user.username == "username"
      assert length(user.documents) == 2

      for document <- user.documents do
        assert_blob(document.blob)
      end
    end

    test "create_record_with_attachment/3 with has_many, file map and extra attribute in attachment" do
      attrs = %{
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
      }

      result =
        Attachments.create_record_with_attachment(
          {%Book{}, &Book.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, Book.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %Book{} = book}} = result
      assert book.title == "title"
      assert length(book.pages) == 2

      for page <- book.pages do
        assert_blob(page.blob)
      end
    end

    test "create_record_with_attachment/3 with has_many, file map (atom) and extra attribute in attachment" do
      attrs = %{
        title: "title",
        pages: %{
          0 => %{
            file: "test/support/images/elixir.png",
            page_number: 1
          },
          1 => %{
            file: "test/support/images/elixir.png",
            page_number: 2
          }
        }
      }

      result =
        Attachments.create_record_with_attachment(
          {%Book{}, &Book.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, Book.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %Book{} = book}} = result
      assert book.title == "title"
      assert length(book.pages) == 2

      for page <- book.pages do
        assert_blob(page.blob)
      end
    end

    test "create_record_with_attachment/3 with has_many, Plug.Upload and extra attribute in attachment" do
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

      result =
        Attachments.create_record_with_attachment(
          {%Book{}, &Book.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, Book.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %Book{} = book}} = result
      assert book.title == "title"
      assert length(book.pages) == 2

      for page <- book.pages do
        assert_blob(page.blob)
      end
    end

    test "update_record_with_attachment/3 with has_one and file map" do
      user = user_fixture([:avatar, :documents])
      old_blob = user.avatar.blob

      attrs = %{
        "username" => "new username",
        "avatar" => %{"file" => "test/support/images/elixir.png"}
      }

      result =
        Attachments.update_record_with_attachment(
          {user, &User.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, User.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      assert user.username == "new username"
      assert_blob(user.avatar.blob)
      refute_blob(old_blob)
    end

    test "update_record_with_attachment/3 with has_one and Plug.Upload" do
      user = user_fixture([:avatar, :documents])
      old_blob = user.avatar.blob

      attrs = %{
        "username" => "new username",
        "avatar" => %Plug.Upload{
          path: "test/support/images/elixir.png",
          content_type: "image/png",
          filename: "elixir.png"
        }
      }

      result =
        Attachments.update_record_with_attachment(
          {user, &User.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, User.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      assert user.username == "new username"
      assert_blob(user.avatar.blob)
      refute_blob(old_blob)
    end

    test "update_record_with_attachment/3 with has_many and file map" do
      user = user_fixture([:avatar, :documents])
      old_blobs = Enum.map(user.documents, &Map.get(&1, :blob))

      attrs = %{
        "username" => "new username",
        "documents" => [
          %{"file" => "test/support/images/elixir.png"},
          %{"file" => "test/support/images/elixir.png"}
        ]
      }

      result =
        Attachments.update_record_with_attachment(
          {user, &User.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, User.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      assert user.username == "new username"
      assert length(user.documents) == 2

      for document <- user.documents do
        assert_blob(document.blob)
      end

      for blob <- old_blobs do
        refute_blob(blob)
      end
    end

    test "update_record_with_attachment/3 with has_many and Plug.Upload" do
      user = user_fixture([:avatar, :documents])
      old_blobs = Enum.map(user.documents, &Map.get(&1, :blob))

      attrs = %{
        "username" => "new username",
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

      result =
        Attachments.update_record_with_attachment(
          {user, &User.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, User.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      assert user.username == "new username"
      assert length(user.documents) == 2

      for document <- user.documents do
        assert_blob(document.blob)
      end

      for blob <- old_blobs do
        refute_blob(blob)
      end
    end

    test "update_record_with_attachment/3 with has_many, file map and extra attribute in attachment" do
      book = book_fixture()
      old_blobs = Enum.map(book.pages, &Map.get(&1, :blob))

      attrs = %{
        "title" => "new title",
        "pages" => %{
          "0" => %{
            "id" => List.first(book.pages).id,
            "file" => "test/support/images/elixir.png",
            "page_number" => 1
          },
          "1" => %{
            "id" => List.last(book.pages).id,
            "file" => "test/support/images/elixir.png",
            "page_number" => 2
          }
        }
      }

      result =
        Attachments.update_record_with_attachment(
          {book, &Book.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, Book.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %Book{} = book}} = result
      assert book.title == "new title"
      assert length(book.pages) == 2

      for page <- book.pages do
        assert_blob(page.blob)
      end

      for blob <- old_blobs do
        refute_blob(blob)
      end
    end

    test "update_record_with_attachment/3 with has_many, Plug.Upload and extra attribute in attachment" do
      book = book_fixture()
      old_blobs = Enum.map(book.pages, &Map.get(&1, :blob))

      attrs = %{
        "title" => "new title",
        "pages" => %{
          "0" => %{
            "id" => List.first(book.pages).id,
            "file" => %Plug.Upload{
              path: "test/support/images/elixir.png",
              content_type: "image/png",
              filename: "elixir.png"
            },
            "page_number" => 1
          },
          "1" => %{
            "id" => List.last(book.pages).id,
            "file" => %Plug.Upload{
              path: "test/support/images/elixir.png",
              content_type: "image/png",
              filename: "elixir.png"
            },
            "page_number" => 2
          }
        }
      }

      result =
        Attachments.update_record_with_attachment(
          {book, &Book.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, Book.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %Book{} = book}} = result
      assert book.title == "new title"
      assert length(book.pages) == 2

      for page <- book.pages do
        assert_blob(page.blob)
      end

      for blob <- old_blobs do
        refute_blob(blob)
      end
    end

    test "update_record_with_attachment/3 with has_many append" do
      user = user_fixture([:avatar, :documents]) |> Map.put(:documents, [])

      attrs = %{
        "username" => "new username",
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

      result =
        Attachments.update_record_with_attachment(
          {user, &User.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, User.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      assert user.username == "new username"

      user = Repo.preload(user, [documents: :blob], force: true)
      assert length(user.documents) == 4

      for document <- user.documents do
        assert_blob(document.blob)
      end
    end

    test "update_record_with_attachment/3 with has_many, update attribute only" do
      book = book_fixture()
      old_page = book.pages |> List.first()
      old_blob = book.pages |> List.last() |> Map.get(:blob)

      attrs = %{
        "title" => "new title",
        "pages" => %{
          "0" => %{
            "id" => List.first(book.pages).id,
            "page_number" => 2
          },
          "1" => %{
            "id" => List.last(book.pages).id,
            "file" => %Plug.Upload{
              path: "test/support/images/elixir.png",
              content_type: "image/png",
              filename: "elixir.png"
            },
            "page_number" => 1
          }
        }
      }

      result =
        Attachments.update_record_with_attachment(
          {book, &Book.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, Book.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %Book{} = book}} = result
      assert book.title == "new title"
      assert length(book.pages) == 2
      assert_blob(List.first(book.pages).blob)
      refute_blob(old_blob)

      assert old_page.blob ==
               book
               |> Repo.preload([pages: :blob], force: true)
               |> Map.get(:pages)
               |> List.last()
               |> Map.get(:blob)
    end

    test "update_record_with_attachment/3 with has_many, update attribute only (atom)" do
      book = book_fixture()
      old_page = book.pages |> List.first()
      old_blob = book.pages |> List.last() |> Map.get(:blob)

      attrs = %{
        title: "new title",
        pages: %{
          0 => %{
            id: List.first(book.pages).id,
            page_number: 2
          },
          1 => %{
            id: List.last(book.pages).id,
            file: %Plug.Upload{
              path: "test/support/images/elixir.png",
              content_type: "image/png",
              filename: "elixir.png"
            },
            page_number: 1
          }
        }
      }

      result =
        Attachments.update_record_with_attachment(
          {book, &Book.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, Book.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %Book{} = book}} = result
      assert book.title == "new title"
      assert length(book.pages) == 2
      assert_blob(List.first(book.pages).blob)
      refute_blob(old_blob)

      assert old_page.blob ==
               book
               |> Repo.preload([pages: :blob], force: true)
               |> Map.get(:pages)
               |> List.last()
               |> Map.get(:blob)
    end

    test "update_record_with_attachment/3 with has_one and no association" do
      user = user_fixture() |> Repo.preload(avatar: :blob)

      attrs = %{
        "username" => "new username",
        "avatar" => %{"file" => "test/support/images/elixir.png"}
      }

      result =
        Attachments.update_record_with_attachment(
          {user, &User.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, User.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      assert user.username == "new username"
      assert_blob(user.avatar.blob)
    end

    test "update_record_with_attachment/3 with has_many and no association" do
      user = user_fixture() |> Repo.preload(documents: :blob)

      attrs = %{
        "username" => "new username",
        "documents" => [
          %{"file" => "test/support/images/elixir.png"},
          %{"file" => "test/support/images/elixir.png"}
        ]
      }

      result =
        Attachments.update_record_with_attachment(
          {user, &User.changeset_with_attachments/2},
          attrs,
          Attachments.attachments_names(attrs, User.attachments())
        )
        |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      assert user.username == "new username"

      for document <- user.documents do
        assert_blob(document.blob)
      end
    end

    test "delete_record_with_attachment/2 with has_one" do
      user = user_fixture([:avatar])

      result =
        Attachments.delete_record_with_attachment(user, [:avatar])
        |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      refute Repo.get(User, user.id)
      refute_blob(user.avatar.blob)
    end

    test "delete_record_with_attachment/2 with has_many" do
      user = user_fixture([:documents])

      result =
        Attachments.delete_record_with_attachment(user, [:documents])
        |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      refute Repo.get(User, user.id)

      for document <- user.documents do
        refute_blob(document.blob)
      end
    end

    test "delete_record_with_attachment/2 with all attachments" do
      user = user_fixture([:avatar, :documents])

      result =
        Attachments.delete_record_with_attachment(user, User.attachments())
        |> Repo.transaction()

      assert {:ok, %{record: %User{} = user}} = result
      refute Repo.get(User, user.id)
      refute_blob(user.avatar.blob)

      for document <- user.documents do
        refute_blob(document.blob)
      end
    end
  end
end
