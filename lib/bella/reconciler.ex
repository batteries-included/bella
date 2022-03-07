defmodule Bella.Reconciler do
  @callback operation(Bella.Reconciler.State.t()) :: K8s.Operation.t()
  @callback reconcile(map(), Bella.Reconciler.State.t()) :: no_return()
end
