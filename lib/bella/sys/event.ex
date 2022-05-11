defmodule Bella.Sys.Event do
  @moduledoc false
  use Bella.Telemetry, name: :bella

  defevent([:watcher, :initialized])
  defevent([:watcher, :first_resource, :started])
  defevent([:watcher, :first_resource, :finished])
  defevent([:watcher, :first_resource, :succeeded])
  defevent([:watcher, :first_resource, :failed])
  defevent([:watcher, :watch, :started])
  defevent([:watcher, :watch, :succeeded])
  defevent([:watcher, :watch, :finished])
  defevent([:watcher, :watch, :down])
  defevent([:watcher, :watch, :failed])
  defevent([:watcher, :watch, :timedout])
  defevent([:watcher, :fetch, :failed])
  defevent([:watcher, :fetch, :succeeded])
  defevent([:watcher, :chunk, :received])
  defevent([:watcher, :chunk, :finished])
  defevent([:watcher, :genserver, :down])

  @doc """
  Measure function execution in _ms_ and return in map w/ results.

  ## Examples
      iex> Bella.Sys.Event.measure(IO, :puts, ["hello"])
      {%{duration: 33}, :ok}
  """
  @spec measure(module, atom, list()) :: {map(), any()}
  def measure(mod, func, args) do
    {duration, result} = :timer.tc(mod, func, args)
    measurements = %{duration: duration}

    {measurements, result}
  end

  def measure(func, args) do
    {duration, result} = :timer.tc(func, args)
    measurements = %{duration: duration}

    {measurements, result}
  end
end
