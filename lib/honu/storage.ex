defmodule Honu.Storage do
  alias Honu.Attachments.Blob

  @type option :: {atom(), any()}

  @callback read(Blob.t(), [option]) :: {:ok, binary()} | {:error, String.t()}
  @callback put(Blob.t(), [option]) :: {:ok, Blob.t()} | {:error, String.t()}
  @callback delete(Blob.t(), [option]) :: :ok | {:error, String.t()}
  @callback exists?(Blob.t() | String.t(), [option]) :: true | false

  def config(key, opts \\ []) do
    Application.fetch_env!(:honu, __MODULE__)
    |> Keyword.merge(opts)
    |> Keyword.fetch!(key)
  end
end
