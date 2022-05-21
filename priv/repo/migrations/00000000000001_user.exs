defmodule HonuTest.Repo.Migrations.User do
  use Ecto.Migration
  require Honu.Migration

  def change do
    Honu.Migration.create_blobs_table()

    create table(:users) do
      add :username, :string
      timestamps()
    end

    Honu.Migration.create_attachments_table(HonuTest.User)
  end
end
