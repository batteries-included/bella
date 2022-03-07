defmodule Bella.Reconciler.Core do
  alias Bella.Reconciler.State
  alias Bella.Sys.Event

  def run(%State{} = state) do
    metadata = State.metadata(state)
    Event.reconciler_run_started(%{}, metadata)

    {measurements, result} = Event.measure(&resources/1, [state])

    case result do
      {:ok, resources} ->
        _ = async_run(resources, measurements, state)

      {:error, error} ->
        metadata = Map.put(metadata, :error, error)
        Event.reconciler_fetch_failed(measurements, metadata)
    end
  end

  defp async_run(resources, measurements, %State{} = state) do
    metadata = State.metadata(state)

    resources
    |> Task.async_stream(fn
      resource when is_map(resource) ->
        Event.reconciler_fetch_succeeded(measurements, metadata)
        reconcile_one(resource, state)

      {:error, error} ->
        metadata = Map.put(metadata, :error, error)
        Event.reconciler_fetch_failed(measurements, metadata)
    end)
    |> Enum.to_list()
  end

  defp resources(%State{connection: connection, client: client, reconciler: reconciler} = state) do
    case reconciler.operation(state) do
      nil ->
        {:ok, []}

      op ->
        client.stream(connection, op)
    end
  end

  defp reconcile_one(resource, %State{reconciler: reconciler} = state) do
    Task.start(fn ->
      {measurements, result} = Event.measure(reconciler, :reconcile, [resource, state])

      metadata =
        state
        |> State.metadata()
        |> Map.put(:name, K8s.Resource.name(resource))
        |> Map.put(:namespace, K8s.Resource.namespace(resource))
        |> Map.put(:kind, K8s.Resource.kind(resource))
        |> Map.put(:api_versions, K8s.Resource.api_version(resource))

      case result do
        :ok ->
          Event.reconciler_reconcile_succeeded(measurements, metadata)

        {:ok, _} ->
          Event.reconciler_reconcile_succeeded(measurements, metadata)

        {:error, error} ->
          metadata = Map.put(metadata, :error, error)
          Event.reconciler_reconcile_failed(measurements, metadata)
      end
    end)
  end
end
