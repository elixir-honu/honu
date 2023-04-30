defmodule Honu.MixProject do
  use Mix.Project

  @source_url "https://github.com/elixir-honu/honu"
  @version "0.3.0"

  def project do
    [
      app: :honu,
      version: @version,
      elixir: "~> 1.12",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      aliases: aliases(),
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Honu",
      source_url: @source_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Honu.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.0"},
      # Web
      {:plug, "~> 1.12"},
      # Storage
      {:aws, "~> 0.11", optional: true},
      # Test / doc
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:ecto_sql, "~> 3.0", only: :test},
      {:postgrex, ">= 0.0.0", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    "A file attachment library for Ecto."
  end

  defp package do
    [
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE* CHANGELOG*),
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
