defmodule Bella.ReconcilerTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Bella.Reconciler

  defmodule NilOperationReconciler do
    @behaviour Reconciler

    @impl true
    def reconcile(_resource, _state) do
      Agent.update(agent_name(), fn _s -> true end)
      :ok
    end

    @impl true
    def operation(_state), do: nil

    def agent_name, do: EverRun
  end

  defmodule ReconcilerCountReconclier do
    @behaviour Reconciler

    @impl true
    def reconcile(_resource, _state) do
      Agent.update(agent_name(), fn count -> count + 1 end)
    end

    @impl true
    def operation(_state), do: K8s.Client.list("reconciler.test.foos/v1", :foos)

    def agent_name, do: PodCountAgent
  end

  describe "Core" do
    test "Core.run works on nil operation" do
      Agent.start_link(fn -> false end, name: NilOperationReconciler.agent_name())
      state = Reconciler.State.new(reconciler: NilOperationReconciler)
      Reconciler.Core.run(state)
      assert Agent.get(NilOperationReconciler.agent_name(), fn state -> state end) == false
    end

    test "Core.run works with PodCountReconciler" do
      Agent.start_link(fn -> 0 end, name: ReconcilerCountReconclier.agent_name())

      state =
        Reconciler.State.new(reconciler: ReconcilerCountReconclier, client: Bella.K8sMockClient)

      Reconciler.Core.run(state)
      assert Agent.get(ReconcilerCountReconclier.agent_name(), fn state -> state end) == 2
    end
  end
end
