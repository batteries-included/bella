defmodule Bella.Reconciler.Worker do
  use GenServer

  alias Bella.Reconciler.Core
  alias Bella.Reconciler.State
  alias Bella.Sys.Event

  def start_link, do: start_link([])

  def start_link(opts) do
    {state_opts, opts} =
      Keyword.split(opts, [
        :client,
        :connection,
        :connection_func,
        :extra,
        :reconciler,
        :frequency,
        :initial_delay
      ])

    GenServer.start_link(__MODULE__, state_opts, opts)
  end

  @impl GenServer
  def init(state_opts) do
    state = State.new(state_opts)
    Event.reconciler_initialized(%{}, State.metadata(state))

    Process.send_after(self(), :run, state.initial_delay)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:run, %State{} = state) do
    Process.send_after(self(), :run, state.frequency)
    Core.run(state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, %State{} = state) do
    Event.reconciler_genserver_down(%{}, State.metadata(state))
    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_info(_other, state) do
    {:noreply, state}
  end
end
