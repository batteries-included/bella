# Bella: Kubernetes Controller Framework

Bella make it easy to create Kubernetes Controllers.

## Installation

Bella can be installed by adding `bella` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bella, "~> 0.1.2"}
  ]
end
```
## Telemetry

Bella uses the `telemetry`  library to emit event metrics.

```elixir
[
  [:bella, :scheduler, :binding, :failed],
  [:bella, :scheduler, :binding, :succeeded],
  [:bella, :scheduler, :nodes, :fetch, :failed],
  [:bella, :scheduler, :nodes, :fetch, :succeeded],
  [:bella, :scheduler, :pods, :fetch, :failed],
  [:bella, :scheduler, :pods, :fetch, :succeeded],
  [:bella, :reconciler, :genserver, :down],
  [:bella, :reconciler, :reconcile, :failed],
  [:bella, :reconciler, :reconcile, :succeeded],
  [:bella, :reconciler, :run, :started],
  [:bella, :reconciler, :fetch, :failed],
  [:bella, :reconciler, :fetch, :succeeded],
  [:bella, :reconciler, :initialized],
  [:bella, :watcher, :genserver, :down],
  [:bella, :watcher, :chunk, :finished],
  [:bella, :watcher, :chunk, :received],
  [:bella, :watcher, :watch, :timedout],
  [:bella, :watcher, :watch, :failed],
  [:bella, :watcher, :watch, :down],
  [:bella, :watcher, :watch, :finished],
  [:bella, :watcher, :watch, :succeeded],
  [:bella, :watcher, :watch, :started],
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
