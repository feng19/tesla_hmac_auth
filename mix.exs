defmodule TeslaHmacAuth.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/feng19/tesla_hmac_auth"

  def project do
    [
      app: :tesla_hmac_auth,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:plug_hmac, "~> 0.5"},
      {:tesla, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: [:docs, :dev], runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "README.md": [title: "Overview"]
      ],
      main: "TeslaHmacAuth",
      source_url: @source_url,
      source_ref: "master",
      formatters: ["html"],
      formatter_opts: [gfm: true]
    ]
  end

  defp package do
    [
      name: "tesla_hmac_auth",
      description: "A tesla middleware, for use with PlugHmac as a http client.",
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["feng19"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
