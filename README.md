# Bella: Kubernetes Controller Framework

Bella make it easy to create Kubernetes GenServers to watch cluster state.

## Installation

Bella can be installed by adding `bella` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bella, "~> 0.2.1"}
  ]
end
```
## Telemetry

Bella uses the `telemetry`  library to emit event metrics.

```elixir
[
  [:bella, :watcher, :genserver, :down],
  [:bella, :watcher, :chunk, :finished],
  [:bella, :watcher, :chunk, :received],
  [:bella, :watcher, :watch, :timedout],
  [:bella, :watcher, :watch, :failed],
  [:bella, :watcher, :watch, :down],
  [:bella, :watcher, :watch, :finished],
  [:bella, :watcher, :watch, :succeeded],
  [:bella, :watcher, :watch, :started],
  [:bella, :watcher, :fetch, :succeeded],
  [:bella, :watcher, :fetch, :failed],
  [:bella, :watcher, :first_resource, :failed],
  [:bella, :watcher, :first_resource, :succeeded],
  [:bella, :watcher, :first_resource, :finished],
  [:bella, :watcher, :first_resource, :started],
  [:bella, :watcher, :initialized]
]
```

## Testing

```elixir
mix test
```
