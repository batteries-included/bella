import Config

if Mix.env() == :test do
  config :logger, level: :error

  config :bella, cluster_name: :test
end

if Mix.env() == :dev do
  config :logger, level: :debug
end
