defmodule HonuTest.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias HonuTest.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import HonuTest.DataCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(HonuTest.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end

  @doc """
  A helper that checks for the presence of a Blob in the Repo database
  and in the defined Storage behaviour.
  """
  def assert_blob(blob) do
    blob.key
    |> Honu.Attachments.get_attachment_by_key!(HonuTest.Repo)
    |> Honu.Storage.config(:storage).exists?()
    |> assert()
  end

  @doc """
  A helper that checks the Blob was marked for deletion.
  """
  def refute_blob(blob) do
    blob.key
    |> Honu.Attachments.get_attachment_by_key!(HonuTest.Repo)
    |> Map.get(:deleted_at)
    |> then(&is_nil(&1))
    |> refute()
  end
end
