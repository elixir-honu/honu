defmodule HonuWeb.Storage.S3 do
  alias Honu.Attachments.Blob
  alias HonuWeb.Storage

  @behaviour Storage

  @impl true
  def url(_conn, blob = %Blob{}, opts \\ []) do
    private_url(blob, opts)
  end

  #defp public_url(blob, opts) do
  #end

  defp private_url(blob, opts) do
    presigned_url(blob, opts)
  end

  defp presigned_url(blob, _opts) do
    metadata = AWS.S3.metadata()

    client =
      Honu.Storage.S3.client()
      |> Map.put(:service, metadata.signing_name)

    headers = []
    query = []

    host = build_host(client, metadata, headers)
    path = blob.key

    url =
      client
      |> build_uri(host, path)
      |> add_query(query, client)
      |> to_string()

    #headers = AWS.Signature.sign_v4(client, now(), "get", url, headers, "")

    now = now()
    :aws_signature.sign_v4_query_params(
      client.access_key_id,
      client.secret_access_key,
      client.region,
      client.service,
      {{now.year, now.month, now.day}, {now.hour, now.minute, now.second}},
      "get",
      url,
      [
        uri_encode_path: false,
        body_digest: "UNSIGNED-PAYLOAD",
        ttl: ttl()
      ]
    )
  end

  defp ttl do
    case HonuWeb.Storage.config(:service_urls_expire_in) do
      {:ok, value} when is_integer(value) -> value
      _ -> 300
    end
  end

  # https://github.com/aws-beam/aws-elixir/blob/master/lib/aws/request.ex

  defp now do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
  end

  #defp build_host(%AWS.Client{} = client, %AWS.ServiceMetadata{} = metadata, headers) do
  defp build_host(client, metadata, headers) do
    build_options = %{
      region: client.region,
      endpoint: client.endpoint,
      service: metadata.signing_name,
      global?: metadata.global?,
      endpoint_prefix: metadata.endpoint_prefix,
      account_id: :proplists.get_value("x-amz-account-id", headers, nil)
    }

    case build_options do
      %{region: "local", endpoint: nil} ->
        "localhost"

      %{endpoint: endpoint} when is_binary(endpoint) ->
        endpoint

      %{endpoint: endpoint_fun} when is_function(endpoint_fun, 1) ->
        endpoint_fun.(build_options)

      %{global?: true, endpoint: endpoint} ->
        endpoint = resolve_endpoint_sufix(endpoint)

        build_final_endpoint([metadata.endpoint_prefix, endpoint], build_options)

      %{endpoint: endpoint} ->
        endpoint = resolve_endpoint_sufix(endpoint)

        build_final_endpoint([metadata.endpoint_prefix, client.region, endpoint], build_options)
    end
  end

  defp resolve_endpoint_sufix({:keep_prefixes, sufix}) when is_binary(sufix) do
    sufix
  end

  defp resolve_endpoint_sufix(nil), do: AWS.Client.default_endpoint()

  defp build_final_endpoint(parts, options) do
    parts =
      if options.endpoint_prefix == "s3-control" do
        account_id = options.account_id || raise "missing account_id"
        [account_id | parts]
      else
        parts
      end

    Enum.join(parts, ".")
  end

  #defp build_uri(%AWS.Client{} = client, host, path) do
  defp build_uri(client, host, path) do
    bucket = Honu.Storage.config!(:s3_bucket)
    URI.merge("#{client.proto}://#{bucket}.#{host}:#{client.port}", path)
  end

  defp add_query(uri = %URI{}, [], _client) do
    uri
  end

  defp add_query(uri = %URI{}, query, client) do
    querystring = AWS.Client.encode!(client, query, :query)

    if is_binary(uri.query) do
      %{uri | query: uri.query <> "&" <> querystring}
    else
      %{uri | query: querystring}
    end
  end
end
