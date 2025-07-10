defmodule BackendFight.MixProject do
  use Mix.Project

  def project do
    [
      app: :backend_fight,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        backend_fight: [
          include_erts: true,
          include_executables_for: [:unix]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {BackendFight.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bandit, "~> 1.7.0"},
      {:bypass, "~> 2.1", only: :test},
      {:broadway, "~> 1.2.1"},
      {:ecto, "~> 3.13.2"},
      {:finch, "~> 0.20"},
      {:gen_stage, "~> 1.3.1"},
      {:jason, "~> 1.4.4"},
      {:mox, "~> 1.2.0", only: :test},
      {:phoenix, "~> 1.7.21"},
      {:quantum, "~> 3.5.3"},
      {:redix, "~> 1.5.2"},
      {:telemetry_metrics, "~> 1.1.0"},
      {:telemetry_poller, "~> 1.2.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get"],
      test: ["test"]
    ]
  end
end
