defprotocol Honu.Upload do
  @spec contents(struct()) :: {:ok, iodata()} | {:error, String.t()}
  def contents(upload)

  @spec filename(struct()) :: String.t()
  def filename(upload)

  @spec content_type(struct()) :: String.t()
  def content_type(upload)

  @spec path(struct()) :: String.t()
  def path(upload)
end

defimpl Honu.Upload, for: Plug.Upload do
  def contents(%{path: path}) do
    case File.read(path) do
      {:error, reason} -> {:error, "Could not read path: #{reason}"}
      success_tuple -> success_tuple
    end
  end

  def filename(%{filename: filename}), do: filename

  def content_type(%{content_type: content_type}) do
    content_type
  end

  def path(%{path: path}), do: path
end

defimpl Honu.Upload, for: BitString do
  def contents(string) do
    case File.read(find_file(string)) do
      {:error, reason} -> {:error, "Could not read path: #{reason}"}
      success_tuple -> success_tuple
    end
  end

  def filename(string) do
    string
    |> find_file()
    |> String.split("/")
    |> List.last()
  end

  def content_type(string) do
    string
    |> find_file()
    |> MIME.from_path()
  end

  def path(string) do
    find_file(string)
  end

  # https://github.com/elixir-lang/elixir/blob/edb5e7e0523dc5fd4470ae9f7b511151beb72aad/lib/elixir/lib/code.ex#L1796
  # If the file is found, returns its path in binary, fails otherwise.
  defp find_file(file) do
    file = Path.expand(file)

    if File.regular?(file) do
      file
    else
      raise "Error in file #{file}."
    end
  end
end
