defmodule Bella.WatcherTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Bella.Watcher
  alias Bella.Watcher.Worker

  doctest Bella.Watcher

  defmodule TestWatcher do
    @behaviour Watcher

    @impl true
    def operation() do
      K8s.Client.list("watcher.test/v1", :foos)
    end

    @impl true
    def add(resource) do
      track_event(:add, resource)
    end

    @impl true
    def modify(resource) do
      track_event(:modify, resource)
    end

    @impl true
    def delete(resource) do
      track_event(:delete, resource)
    end

    @spec track_event(atom, map) :: :ok
    def track_event(type, resource) do
      event = {type, resource}
      Agent.update(TestWatcherCache, fn events -> [event | events] end)
    end

    def start do
      Agent.start_link(fn -> [] end, name: TestWatcherCache)
    end

    def get_events do
      Agent.get(TestWatcherCache, fn events -> events end)
    end
  end

  setup do
    {:ok, _pid} = TestWatcher.start()
    :ok
  end

  test "watch/3" do
    {:ok, pid} =
      Worker.start_link(watcher: TestWatcher, client: Bella.K8sMockClient, resource_version: "3")

    Watcher.Core.watch(pid, Worker.state(pid))
    Process.sleep(500)

    events = TestWatcher.get_events()
    refute events == []
  end

  describe "dispatch/2" do
    test "dispatches ADDED events to the given module's handler function" do
      evt = event("ADDED")
      Watcher.Core.dispatch(evt, TestWatcher)

      # Professional.
      :timer.sleep(100)
      assert [event] = TestWatcher.get_events()
      assert {:add, %{"apiVersion" => "example.com/v1"}} = event
    end

    test "dispatches MODIFIED events to the given module's handler function" do
      evt = event("MODIFIED")
      Watcher.Core.dispatch(evt, TestWatcher)

      # Professional.
      :timer.sleep(100)
      assert [event] = TestWatcher.get_events()
      assert {:modify, %{"apiVersion" => "example.com/v1"}} = event
    end

    test "dispatches DELETED events to the given module's handler function" do
      evt = event("DELETED")
      Watcher.Core.dispatch(evt, TestWatcher)

      # Professional.
      :timer.sleep(100)
      assert [event] = TestWatcher.get_events()
      assert {:delete, %{"apiVersion" => "example.com/v1"}} = event
    end
  end

  defp event(type) do
    %{
      "object" => %{
        "apiVersion" => "example.com/v1",
        "kind" => "Widget",
        "metadata" => %{
          "name" => "test-widget",
          "namespace" => "default",
          "resourceVersion" => "705460"
        }
      },
      "type" => type
    }
  end
end
