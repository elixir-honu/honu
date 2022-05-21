defmodule HonuTest.Repo.Migrations.Book do
  use Ecto.Migration
  require Honu.Migration

  def change do
    create table(:books) do
      add :title, :string
      timestamps()
    end

    Honu.Migration.create_attachments_table(HonuTest.Book)

    alter table("honu_book_attachments") do
      add :page_number, :integer
    end

    create unique_index("honu_book_attachments", [:record_id, :page_number])
  end
end
