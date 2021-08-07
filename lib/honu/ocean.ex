defmodule Honu.Ocean do
  import Ecto.Query

  use GenServer

  @interval 2

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Process.send_after(self(), :work, 5000)
    {:ok, %{last_run_at: nil}}
  end

  def handle_info(:work, _state) do
    clean()
    schedule_work()

    {:noreply, %{last_run_at: :calendar.local_time()}}
  end

  defp clean do
    repo = Honu.Storage.config(:repo)
    now = NaiveDateTime.utc_now()

    Honu.Attachments.Blob
    |> where([b], b.deleted_at < ^now)
    |> repo.all()
    |> Enum.each(fn blob ->
      # Some might fail, they will be tried next time
      Honu.Attachments.delete_blob(blob, repo)
    end)
  end

  defp schedule_work do
    Process.send_after(self(), :work, @interval * 60 * 60 * 1000)
  end
end
