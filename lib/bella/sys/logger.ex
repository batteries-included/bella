defmodule Bella.Sys.Logger do
  @moduledoc """
  Attaches telemetry events to the Elixir Logger
  """

  require Logger

  @spec attach() :: :ok
  @doc """
  Attaches telemetry events to the Elixir Logger
  """
  def attach do
    events = Bella.Sys.Event.events()
    :telemetry.attach_many("bella-events-logger", events, &Bella.Sys.Logger.log_handler/4, :debug)
  end

  @doc false
  @spec log_handler(keyword, map | integer, map, atom) :: :ok
  def log_handler(event, measurements, metadata, preferred_level) do
    event_name = Enum.join(event, ".")

    level = log_level(event, preferred_level)
    Logger.log(level, "[#{event_name}] #{inspect(measurements)} #{inspect(metadata)}")
  end

  defp log_level(event, preferred_level) do
    case is_error(event) do
      true -> :error
      _ -> preferred_level
    end
  end

  defp is_error(event), do: Enum.any?(event, fn part -> part == :error || part == :fail end)
end
