defmodule TeslaHmacAuthTest do
  use ExUnit.Case

  setup do
    Tesla.Mock.mock(fn
      %{method: :get} = env ->
        %{path: path} = URI.parse(env.url)
        "hmac " <> credential = Tesla.get_header(env, "Authorization")
        credential = PlugHmac.split_params_from_string(credential)

        conn = %{
          method: "GET",
          request_path: path,
          query_string: URI.encode_query(env.query),
          assigns: %{raw_body: env.body}
        }

        if PlugHmac.check_sign?(:sha256, &get_secret/1, credential, conn) do
          %Tesla.Env{status: 200, body: "ok"}
        else
          %Tesla.Env{status: 200, body: "error"}
        end
    end)

    :ok
  end

  test "Setting by client_id & secret" do
    assert {:ok, env} =
             Tesla.client([{TeslaHmacAuth, [client_id: "id-01", secret: "secret-01"]}])
             |> Tesla.get("https://example.com/path/aa/bb/cc", query: [hello: "world"])

    assert env.status == 200
    assert env.body == "ok"
  end

  test "Setting by get_secret_fun" do
    assert {:ok, env} =
             Tesla.client([{TeslaHmacAuth, [get_secret_fun: &__MODULE__.get_secret/0]}])
             |> Tesla.get("https://example.com/path/aa/bb/cc", query: [hello: "world"])

    assert env.status == 200
    assert env.body == "ok"
  end

  test "Setting by config" do
    Application.put_env(:tesla_hmac_auth, :auth, {"id-03", "secret-03"})

    assert {:ok, env} =
             Tesla.client([TeslaHmacAuth])
             |> Tesla.get("https://example.com/path/aa/bb/cc", query: [hello: "world"])

    assert env.status == 200
    assert env.body == "ok"
  end

  def get_secret do
    {:ok, "id-02", "secret-02"}
  end

  defp get_secret("id-01"), do: {:ok, "secret-01"}
  defp get_secret("id-02"), do: {:ok, "secret-02"}
  defp get_secret("id-03"), do: {:ok, "secret-03"}
  defp get_secret(_client_id), do: {:error, :not_found}
end
