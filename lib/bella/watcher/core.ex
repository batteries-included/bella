defmodule Bella.Watcher.Core do
  alias Bella.Sys.Event
  alias Bella.Watcher.ResourceVersion
  alias Bella.Watcher.State

  def watch(
        pid,
        %State{
          connection: conn,
          watcher: watcher,
          client: client,
          resource_version: rv,
          watch_timeout: watch_timeout
        } = state
      ) do
    client.watch(conn, watcher.operation(state),
      params: [resourceVersion: rv],
      stream_to: pid,
      recv_timeout: watch_timeout
    )
  end

  def get_resource_version(%State{} = state) do
    resp = fetch_resource_version(state)

    case resp do
      {:ok, rv} ->
        rv

      {:error, _} ->
        "0"

      _ ->
        "0"
    end
  end

  def process_lines(lines, %State{resource_version: start_rv} = state) do
    Enum.reduce(lines, {:ok, start_rv}, fn line, status ->
      case status do
        {:ok, current_rv} ->
          process_line(line, %State{state | resource_version: current_rv})

        {:error, :gone} ->
          {:error, :gone}
      end
    end)
  end

  def process_line(line, %State{resource_version: current_rv} = state) do
    %{"type" => type, "object" => raw_object} = Jason.decode!(line)

    case ResourceVersion.extract_rv(raw_object) do
      {:gone, _message} ->
        {:error, :gone}

      ^current_rv ->
        {:ok, current_rv}

      new_rv ->
        dispatch(%{"type" => type, "object" => raw_object}, state)
        {:ok, new_rv}
    end
  end

  def get_before(state) do
    metadata = State.metadata(state)
    Event.watcher_first_resource_started(%{}, metadata)
    {measurements, result} = Event.measure(&first_resources/1, [state])
    Event.watcher_first_resource_finished(measurements, metadata)

    case result do
      {:ok, resources} ->
        _ = async_run(resources, measurements, state)

      {:error, error} ->
        metadata = Map.put(metadata, :error, error)
        Event.watcher_first_resource_failed(measurements, metadata)
    end
  end

  defp first_resources(%State{connection: conn, watcher: watcher, client: client} = state) do
    case watcher.operation(state) do
      nil ->
        {:ok, []}

      op ->
        client.stream(conn, op)
    end
  end

  defp async_run(resources, measurements, %State{watcher: watcher, resource_version: rv} = state) do
    metadata = State.metadata(state)

    resources
    |> Enum.map(fn
      resource when is_map(resource) ->
        Event.watcher_fetch_succeeded(measurements, metadata)

        case is_before(resource, rv) do
          true ->
            do_dispatch(watcher, :add, [resource, state])

          _false ->
            nil
        end

      {:error, error} ->
        metadata = Map.put(metadata, :error, error)
        Event.watcher_fetch_failed(measurements, metadata)
        nil
    end)
    |> Enum.filter(fn r -> r != nil end)
    |> Task.await_many()
  end

  @doc """
  Dispatches an `ADDED`, `MODIFIED`, and `DELETED` events to an controller
  """
  @spec dispatch(map, State.t()) :: no_return
  def dispatch(%{"type" => "ADDED", "object" => object}, %State{watcher: watcher} = state),
    do: do_dispatch(watcher, :add, [object, state])

  def dispatch(%{"type" => "MODIFIED", "object" => object}, %State{watcher: watcher} = state),
    do: do_dispatch(watcher, :modify, [object, state])

  def dispatch(%{"type" => "DELETED", "object" => object}, %State{watcher: watcher} = state),
    do: do_dispatch(watcher, :delete, [object, state])

  @spec do_dispatch(atom, atom, list()) :: no_return
  defp do_dispatch(watcher, event, args) do
    Task.async(fn ->
      apply(watcher, event, args)
    end)
  end

  defp fetch_resource_version(%{connection: conn, watcher: watcher, client: client} = state) do
    with {:ok, payload} <- client.run(conn, watcher.operation(state)) do
      rv = ResourceVersion.extract_rv(payload)
      {:ok, rv}
    end
  end

  defp is_before(resource, rv) do
    case ResourceVersion.extract_rv(resource) do
      {:error, _} ->
        true

      resource_rv ->
        String.to_integer(resource_rv) <= String.to_integer(rv)
    end
  end
end
