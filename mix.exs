defmodule Graphvix.Mixfile do
  use Mix.Project

  def project do
    [app: :graphvix,
     version: "0.5.0",
     description: "Graphviz in Elixir",
     package: [
       licenses: ["MIT"],
       maintainers: maintainers(),
       links: %{
         github: "https://github.com/mikowitz/graphvix"
       }
     ],
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],
     mod: {Graphvix, []}]
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
      {:ex_doc, "~> 0.14", only: :dev},
      {:espec, "~> 1.1.0", only: :test},
      {:mix_test_watch, "~> 0.2", only: [:dev, :test]}
    ]
  end

  defp maintainers do
    [
      "Michael Berkowitz"
    ]
  end
end
