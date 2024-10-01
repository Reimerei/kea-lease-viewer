defmodule KeaLeaseViewer.MixProject do
  use Mix.Project

  def project do
    [
      app: :kea_lease_viewer,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        release: [
          include_executables_for: [:unix]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {KeaLeaseViewer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:plug, "~> 1.15"},
      {:bandit, "~> 1.2"},
      {:ip, "~> 2.0"},
      {:zoneinfo, "~> 0.1"},
      {:remote_ip, "~> 1.1"},
      {:ex_syslogger, "~> 2.1"}
    ]
  end
end
