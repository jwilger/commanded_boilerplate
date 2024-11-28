defmodule CommandedBoilerplate.MixProject do
  use Mix.Project

  def project do
    [
      app: :commanded_boilerplate,
      version: "0.1.1",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
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

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:commanded, "~> 1.4"},
      {:commanded_ecto_projections, "~> 1.4"},
      {:commanded_eventstore_adapter, "~> 1.4"},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:hammox, "~> 0.7", only: :test},
      {:jason, ">= 1.2.0"},
      {:mix_test_interactive, "~> 4.0", only: [:dev, :test]},
      {:mox, "~> 1.1", only: :test},
      {:newt, ">= 8.0.1"},
      {:stream_data, ">= 0.0.0"},
      {:typed_ecto_schema, "~> 0.4"},
      {:typed_struct, "~> 0.3"},
      {:vex, ">= 0.9.0"}
    ]
  end
end
