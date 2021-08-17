use Mix.Config

if Mix.env() == :test do
  config :logger, level: :error

  config :bella, k8s_client: Bella.K8sMockClient

  config :bella, cluster_name: :test
end

if Mix.env() == :dev do
  config :logger, level: :debug

  config :mix_test_watch,
    tasks: [
      "test --cover",
      "format",
      "credo"
    ]
end
