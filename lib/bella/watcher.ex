defmodule Bella.Watcher do
  @callback operation() :: K8s.Operation.t()

  @callback add(map()) :: :ok | :error
  @callback modify(map()) :: :ok | :error
  @callback delete(map()) :: :ok | :error
end
