defmodule WhatYouListen.MixProject do
  use Mix.Project

  def project do
    [
      app: :what_you_listen,
      version: "0.1.0",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        what_you_listen: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent],
          path: "./rel/what_you_listen",
          quiet: true
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {WhatYouListen.Application, []},
      extra_applications: [:logger, :runtime_tools, :inets]
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
      {:phoenix, "~> 1.4.10"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:amqp, "~> 1.3.2"},
      {:gelf_logger, "~> 0.9", only: ~w(stage prod server_dev)a},

      # OCR
      {:tesseract_ocr, "~> 0.1.0"},

      # Linters
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
