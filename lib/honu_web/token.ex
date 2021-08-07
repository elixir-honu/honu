defmodule HonuWeb.Token do
  # https://github.com/phoenixframework/phoenix/blob/master/lib/phoenix/token.ex

  def sign(context, salt, data, opts \\ []) when is_binary(salt) do
    context
    |> get_key_base()
    |> Plug.Crypto.sign(salt, data, opts)
  end

  def verify(context, salt, token, opts \\ []) when is_binary(salt) do
    context
    |> get_key_base()
    |> Plug.Crypto.verify(salt, token, opts)
  end

  ## Helpers

  defp get_key_base(endpoint) when is_atom(endpoint),
    do: get_endpoint_key_base(endpoint)

  defp get_key_base(string) when is_binary(string) and byte_size(string) >= 20,
    do: string

  defp get_endpoint_key_base(endpoint) do
    endpoint.config(:secret_key_base) ||
      raise """
      no :secret_key_base configuration found in #{inspect(endpoint)}.
      Ensure your environment has the necessary mix configuration. For example:
          config :my_app, MyAppWeb.Endpoint,
              secret_key_base: ...
      """
  end
end
