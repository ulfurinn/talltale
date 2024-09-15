defmodule Talltale.MixProject do
  use Mix.Project

  def project do
    [
      app: :talltale,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Talltale.Application, []},
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
      {:arrays, "~> 2.0"},
      {:bandit, "~> 1.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:gettext, "~> 0.20"},
      {:html_entities, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.0"},
      {:phoenix, "~> 1.7.7"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:uniq, "~> 0.1"},
      {:yaml_elixir, "~> 2.9"},
      {:ymlr, "~> 5.0"},
      ### patch
      {:type_check, github: "ulfurinn/elixir-type_check", override: true}
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
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": [
        "esbuild.install --if-missing",
        "cmd npm install --prefix assets"
      ],
      "assets.build": ["esbuild default"],
      "assets.deploy": [
        "esbuild default --minify",
        "cmd npx sass ./assets/css/main.scss ./priv/static/assets/main.css --load-path ./assets/css --load-path ./assets/node_modules",
        "phx.digest"
      ]
    ]
  end
end
