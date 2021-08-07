defmodule Honu.MixProject do
  use Mix.Project

  def project do
    [
      app: :honu,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:plug, "~> 1.12"}
    ]
  end
end
