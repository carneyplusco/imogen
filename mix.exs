defmodule Imogen.MixProject do
  use Mix.Project

  def project do
    [
      app: :imogen,
      version: "0.1.0",
      elixir: ">= 1.6.0",
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
      {:sweet_xml, "~> 0.6.5"},
      {:nimble_csv, "~> 0.3"},
      {:jason, "~> 1.0.0"},
      {:flow, "~> 0.11"},
      {:mogrify, "~> 0.5.6"},
      {:httpoison, "~> 1.0"},
      {:sshkit, "~> 0.0.3"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
