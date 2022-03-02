defmodule Bella.Watcher.Worker do
  @moduledoc """
  Continuously watch a list `Operation` for `add`, `modify`, and `delete` events.
  """

  use GenServer

  alias Bella.Sys.Event
  alias Bella.Watcher.Core
  alias Bella.Watcher.State

  def start_link, do: start_link([])

  def start_link(opts) do
    {state_opts, opts} =
      Keyword.split(opts, [
        :client,
        :connection,
        :watcher,
        :resource_version,
        :watch_timeout,
        :initial_delay
      ])

    GenServer.start_link(__MODULE__, state_opts, opts)
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  @impl GenServer
  def init(state_opts) do
    state = State.new(state_opts)
    Event.watcher_initialized(%{}, State.metadata(state))

    Process.send_after(self(), :watch, state.initial_delay)
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:state, _from, %State{} = state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_info(:watch, %State{resource_version: curr_rv} = state) do
    rv = curr_rv || Core.get_resource_version(state)
    state = %{state | resource_version: rv}

    if is_first_watch(curr_rv, rv) do
      _res = Core.get_before(state)
    end

    Event.watcher_watch_started(%{}, State.metadata(state))
    {:ok, ref} = Core.watch(self(), state)

    state = %State{state | k8s_watcher_ref: ref}
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(%HTTPoison.AsyncHeaders{}, state), do: {:noreply, state}

  @impl GenServer
  def handle_info(%HTTPoison.AsyncStatus{code: 200}, state) do
    Event.watcher_watch_succeeded(%{}, State.metadata(state))
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(%HTTPoison.AsyncStatus{code: code}, state) do
    metadata = state |> State.metadata() |> Map.put(:code, code)
    Event.watcher_watch_failed(%{}, metadata)
    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_info(%HTTPoison.AsyncChunk{chunk: chunk}, %State{} = state) do
    metadata = State.metadata(state)
    Event.watcher_chunk_received(%{}, metadata)

    {lines, buffer} =
      state.buffer
      |> Bella.Watcher.ResponseBuffer.add_chunk(chunk)
      |> Bella.Watcher.ResponseBuffer.get_lines()

    case Core.process_lines(lines, state) do
      {:ok, new_rv} ->
        Event.watcher_chunk_finished(%{}, metadata)
        {:noreply, %State{state | buffer: buffer, resource_version: new_rv}}

      {:error, :gone} ->
        Event.watcher_chunk_finished(%{}, metadata)
        {:stop, :normal, state}

      _ ->
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(%HTTPoison.AsyncEnd{}, %State{} = state) do
    Event.watcher_watch_finished(%{}, State.metadata(state))
    send(self(), :watch)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(%HTTPoison.Error{reason: {:closed, :timeout}}, %State{} = state) do
    Event.watcher_watch_timedout(%{}, State.metadata(state))
    send(self(), :watch)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _pid, _reason}, %State{k8s_watcher_ref: k8s_ref} = state) do
    case ref == k8s_ref do
      true ->
        # If the watcher is down then restart it.
        Event.watcher_watch_down(%{}, State.metadata(state))
        state = %State{state | k8s_watcher_ref: nil}

        send(self(), :watch)
        {:noreply, state}

      _ ->
        # Otherwise we assume that it was an async task dispatched to the
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(_other, %State{} = state) do
    {:noreply, state}
  end

  defp is_first_watch(previous_rv, new_rv), do: previous_rv == nil && new_rv != nil
end
