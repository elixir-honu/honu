defmodule Mix.Tasks.Honu.Clean do
  use Mix.Task

  @storage_folder "storage"
  @do_not_remove [".keep"]

  def run(_args) do
    with {:ok, paths} <- File.ls(@storage_folder) do
      Enum.each(paths, fn p ->
        if p not in @do_not_remove do
          File.rm_rf(Path.expand(p, @storage_folder))
        end
      end)
    end
  end
end
