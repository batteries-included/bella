defmodule Bella.Watcher.Core do
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
        } = _s
      ) do
    client.watch(conn, watcher.operation(),
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

  def process_line(line, %State{resource_version: current_rv, watcher: watcher} = _s) do
    %{"type" => type, "object" => raw_object} = Jason.decode!(line)

    case ResourceVersion.extract_rv(raw_object) do
      {:gone, _message} ->
        {:error, :gone}

      ^current_rv ->
        {:ok, current_rv}

      new_rv ->
        dispatch(%{"type" => type, "object" => raw_object}, watcher)
        {:ok, new_rv}
    end
  end

  @doc """
  Dispatches an `ADDED`, `MODIFIED`, and `DELETED` events to an controller
  """
  @spec dispatch(map, atom) :: no_return
  def dispatch(%{"type" => "ADDED", "object" => object}, watcher),
    do: do_dispatch(watcher, :add, object)

  def dispatch(%{"type" => "MODIFIED", "object" => object}, watcher),
    do: do_dispatch(watcher, :modify, object)

  def dispatch(%{"type" => "DELETED", "object" => object}, watcher),
    do: do_dispatch(watcher, :delete, object)

  @spec do_dispatch(atom, atom, map) :: no_return
  defp do_dispatch(watcher, event, object) do
    Task.start(fn ->
      apply(watcher, event, [object])
    end)
  end

  defp fetch_resource_version(%{connection: conn, watcher: watcher, client: client} = _state) do
    with {:ok, payload} <- client.run(conn, watcher.operation()) do
      rv = ResourceVersion.extract_rv(payload)
      {:ok, rv}
    end
  end
end
