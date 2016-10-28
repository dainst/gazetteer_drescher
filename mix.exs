defmodule GazetteerDrescher.Mixfile do
  use Mix.Project

  def project do
    [app: :gazetteer_drescher,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     escript: escript,
     docs: [output: "docs"]
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger, :httpoison, :poison, :timex ]
      # mod: {GazetteerDrescher, []}
    ]
  end

  def escript do
    [ main_module: GazetteerDrescher.CLI ]
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
      {:httpoison, "~> 0.9.0"},
      {:poison, "~> 3.0"},
      {:timex, "~> 3.0"},
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end
end
