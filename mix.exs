defmodule Graphvix.Mixfile do
  use Mix.Project

  @source_url "https://github.com/mikowitz/graphvix"
  @version "1.0.0"

  def project do
    [
      app: :graphvix,
      version: @version,
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
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

  defp package do
    [
        description: "Elixir interface for Graphviz",
        maintainers: ["Michael Berkowitz"],
        licenses: ["MIT"],
        links: %{
          GitHub: @source_url
        }
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", github: "elixir-lang/ex_doc", branch: "master", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 0.2", only: [:dev, :test]},
      {:stream_data, "~> 0.1", only: [:dev, :test]},
      {:credo, "~> 1.0.5", only: [:dev]}
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end
