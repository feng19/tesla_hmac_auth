defmodule TeslaHmacAuth do
  @moduledoc """
  A tesla middleware, for use with PlugHmac as a http client.

  ### Example usage

  - Setting by client_id & secret:
    ```elixir
    defmodule MyClient do
      use Tesla
      plug #{inspect(__MODULE__)}, client_id: "id", secret: "secret"
    end
    ```

  - Setting by get_secret_fun:
    ```elixir
    defmodule MyClient do
      use Tesla
      plug #{inspect(__MODULE__)}, get_secret_fun: &MyConfig.get_secret/0
    end
    ```

  - Setting by config:
  `config :tesla_hmac_auth, auth: {"client_id", "secret"}`
    ```elixir
    defmodule MyClient do
      use Tesla
      plug #{inspect(__MODULE__)}
    end
    ```
  """

  @behaviour Tesla.Middleware

  def call(env, next, opts) when is_list(opts) do
    call(env, next, Map.new(opts))
  end

  def call(env, next, %{client_id: client_id, secret: secret} = opts) do
    env
    |> make_header(fn -> {:ok, client_id, secret} end, Map.drop(opts, [:client_id, :secret]))
    |> Tesla.run(next)
  end

  def call(env, next, %{get_secret_fun: fun} = opts) when is_function(fun, 0) do
    env
    |> make_header(fun, Map.delete(opts, :get_secret_fun))
    |> Tesla.run(next)
  end

  def call(env, next, opts) do
    env
    |> make_header(&__MODULE__.get_secret/0, opts || %{})
    |> Tesla.run(next)
  end

  defp make_header(env, get_secret_fun, opts) do
    key = Map.get(opts, :client_signature_name, "Authorization")
    hmac_algo = Map.get(opts, :hmac_algo, :sha256)
    method = to_string(env.method) |> String.upcase()
    %{path: path} = URI.parse(env.url)

    value =
      PlugHmac.make_header(
        hmac_algo,
        get_secret_fun,
        method,
        path,
        URI.encode_query(env.query),
        env.body,
        nil
      )

    Tesla.put_header(env, key, value)
  end

  def get_secret do
    {client_id, secret} = Application.fetch_env!(:tesla_hmac_auth, :auth)
    {:ok, client_id, secret}
  end
end
