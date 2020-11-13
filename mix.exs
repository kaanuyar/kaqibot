defmodule Kaqibot.MixProject do
  use Mix.Project

  def project do
    [
      app: :kaqibot,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
	  releases: [
		kaqibot: [
			include_executables_for: [:windows],
			applications: [runtime_tools: :permanent]
		]
	  ],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
	  applications: [:logger, :exirc, :inets, :ssl, :poison, :plug_cowboy],
	  mod: {Kaqibot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
	  {:exirc, "~> 1.1"},
	  {:poison, "~> 3.1"},
	  {:plug_cowboy, "~> 2.4"}
    ]
  end
end
