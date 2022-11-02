defmodule Honu.Migration do
  defmacro create_blobs_table do
    quote do
      create table(:honu_blobs, primary_key: false) do
        add(:id, :binary_id, primary_key: true)
        add(:key, :string, null: false)
        add(:filename, :text, null: false)
        add(:content_type, :string)
        add(:metadata, :map)
        add(:byte_size, :bigint, null: false)
        add(:checksum, :text, null: false)
        add(:deleted_at, :naive_datetime)

        timestamps()
      end

      create(unique_index(:honu_blobs, [:key]))
    end
  end

  defmacro create_attachments_table(module, opts \\ []) do
    quote bind_quoted: [module: module, opts: opts] do
      table_name =
        module
        |> to_string()
        |> String.split(".")
        |> List.last()
        |> String.downcase()
        |> (&"honu_#{&1}_attachments").()

      record_table = String.to_atom(module.__schema__(:source))

      create table(table_name, primary_key: false) do
        add(:id, :binary_id, primary_key: true)
        add(:name, :string, null: false)

        add(
          :blob_id,
          references(:honu_blobs, column: :id, type: :binary_id, on_delete: :delete_all)
        )

        case module.__schema__(:type, :id) do
          :id ->
            add(:record_id, references(record_table, column: :id, on_delete: :delete_all))

          :binary_id ->
            add(
              :record_id,
              references(record_table, column: :id, type: :binary_id, on_delete: :delete_all)
            )

          pk ->
            raise "Primary key #{pk} not supported."
        end

        timestamps(opts)
      end

      create(unique_index(table_name, [:name, :record_id, :blob_id]))
    end
  end
end
