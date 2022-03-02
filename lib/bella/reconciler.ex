defmodule Bella.Reconciler do
  alias Bella.Reconciler.State

  @callback operation() :: K8s.Operation.t()
  @callback reconcile(map(), State) :: no_return()
end
