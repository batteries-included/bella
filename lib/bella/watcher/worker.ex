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
    Event.watcher_watch_started(%{}, State.metadata(state))
    Core.watch(self(), state)
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
    Event.watcher_chunk_received(%{}, State.metadata(state))

    {lines, buffer} =
      state.buffer
      |> Bella.Watcher.ResponseBuffer.add_chunk(chunk)
      |> Bella.Watcher.ResponseBuffer.get_lines()

    case Core.process_lines(lines, state) do
      {:ok, new_rv} ->
        {:noreply, %State{state | buffer: buffer, resource_version: new_rv}}

      {:error, :gone} ->
        {:stop, :normal, state}
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
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, %State{} = state) do
    Event.watcher_genserver_down(%{}, State.metadata(state))

    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_info(_other, %State{} = state) do
    {:noreply, state}
  end
end