defmodule HonuWeb.Storage do
  alias Honu.Attachments.Blob

  @type option :: {atom(), any()}

  @callback url(Blob.t(), [option]) :: {:ok, String.t()} | {:error, String.t()}
  # @callback url_for_direct_upload() :: {:ok, String.t()} | {:error, String.t()}
  # @callback headers_for_direct_upload() :: {:ok, map()} | {:error, String.t()}

  def config(key, opts \\ []) do
    Application.fetch_env!(:honu, __MODULE__)
    |> Keyword.merge(opts)
    |> Keyword.fetch(key)
  end

  def config!(key, opts \\ []) do
    Application.fetch_env!(:honu, __MODULE__)
    |> Keyword.merge(opts)
    |> Keyword.fetch!(key)
  end

  def namespace do
    Application.fetch_env!(:honu, __MODULE__)
    |> Keyword.fetch(:namespace)
    |> case do
      :error -> "honu"
      namespace -> namespace
    end
  end

  def base_url(conn) do
    "#{conn.scheme}://#{conn.host}:#{conn.port}"
  end

  def sanitized_filename(filename) do
    filename
  end

  def default_crypto_opts do
    # https://github.com/rails/rails/pull/6952#issuecomment-7661220
    [
      key_iterations: 1000,
      key_length: 256,
      key_digest: :sha256,
      max_age: config!(:service_urls_expire_in)
    ]
  end

  def permanent_opts do
    [signed_at: 0, max_age: 31_536_000_000]
  end

  def generate_data(data, opts \\ []) do
    HonuWeb.Token.sign(
      HonuWeb.Storage.config!(:secret_key_base),
      "blob_id",
      data,
      Keyword.merge(default_crypto_opts(), opts)
    )
    |> Base.url_encode64()
  end

  def generate_digest(data) do
    :crypto.mac(:hmac, :sha256, HonuWeb.Storage.config!(:secret_key_base), data)
    |> Base.encode16(case: :lower)
  end

  def content_disposition_with(filename, type \\ "inline") do
    disposition = Enum.find(["inline", "attachment"], "inline", fn x -> x == type end)

    %{
      disposition: disposition,
      filename: sanitized_filename(filename)
    }
  end

  def decode_verified_key(encoded_key, purpose \\ "blob_id") do
    token =
      encoded_key
      |> String.split("--")
      |> List.first()
      |> Base.url_decode64!()

    case verify_token(token, purpose) do
      {:ok, map} -> {:ok, map}
      {:error, _} -> {:error, "Expired"}
    end
  end

  def find_signed(signed_blob_id, purpose \\ "blob_id", opts \\ []) do
    token =
      signed_blob_id
      |> String.split("--")
      |> List.first()
      |> Base.url_decode64!()

    case verify_token(token, purpose, opts) do
      {:ok, key} ->
        {:ok, Honu.Attachments.get_attachment_by_key!(key, config!(:repo))}

      {:error, _} ->
        {:error, "Expired"}
    end
  end

  defp verify_token(token, purpose, opts \\ []) do
    HonuWeb.Token.verify(
      HonuWeb.Storage.config!(:secret_key_base),
      purpose,
      token,
      Keyword.merge(default_crypto_opts(), opts)
    )
  end
end
