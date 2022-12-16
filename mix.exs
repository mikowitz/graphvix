defmodule Graphvix.Mixfile do
  use Mix.Project

  @version "1.1.0"
  @maintainers [
    "Michael Berkowitz"
  ]
  @links %{
    github: "https://github.com/mikowitz/graphvix"
  }

  def project do
    [
      app: :graphvix,
      version: @version,
      description: "Elixir interface for Graphviz",
      package: [
        maintainers: @maintainers,
        licenses: ["MIT"],
        links: @links
      ],
      elixir: "~> 1.13",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 0.5", only: [:dev, :test]}
    ]
  end
end
