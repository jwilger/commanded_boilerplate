defmodule CommandedAggregateless.MixProject do
  use Mix.Project

  def project do
    [
      app: :commanded_aggregateless,
      version: "1.0.0",
      elixir: "~> 1.20",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "Helpers for building aggregate-less Commanded workflows with validation, authorization, command routing, and read-store queries.",
      package: package(),
      docs: docs()
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
      {:ex_doc, "~> 0.40.3", only: :dev, runtime: false},
      {:hammox, "~> 0.7", only: :test},
      {:jason, ">= 1.2.0"},
      {:mix_test_interactive, "~> 5.1", only: [:dev, :test]},
      {:mox, "~> 1.1", only: :test},
      {:newt, "~> 10.0"},
      {:stream_data, ">= 0.0.0"},
      {:typed_ecto_schema, "~> 0.4"},
      {:typed_struct, "~> 0.3"},
      {:vex, ">= 0.9.0"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/jwilger/commanded_aggregateless"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      skip_undefined_reference_warnings_on: &String.starts_with?(&1, "Vex.Validators.")
    ]
  end
end
