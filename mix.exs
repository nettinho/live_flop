defmodule LiveFlop.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_flop,
      version: "0.0.2",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:flop, "~> 0.26.1"},
      {:flop_phoenix, "~> 0.23.1"}
    ]
  end
end
