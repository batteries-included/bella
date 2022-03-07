defmodule Bella.Watcher do
  @callback operation(Bella.Watcher.State.t()) :: K8s.Operation.t()

  @callback add(map(), Bella.Watcher.State.t()) :: :ok | :error
  @callback modify(map(), Bella.Watcher.State.t()) :: :ok | :error
  @callback delete(map(), Bella.Watcher.State.t()) :: :ok | :error
end
