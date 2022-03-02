defmodule Bella.Watcher.State do
  @moduledoc "State of the Watcher"

  alias Bella.Watcher.ResponseBuffer

  @type t :: %__MODULE__{
          watcher: Bella.Watcher,
          buffer: ResponseBuffer.t(),
          resource_version: String.t() | nil,
          client: module(),
          connection: K8s.Conn.t() | nil,
          initial_delay: integer()
        }

  @default_initial_delay 500
  @default_watch_timeout 64_000

  defstruct client: nil,
            connection: nil,
            watcher: nil,
            buffer: nil,
            resource_version: nil,
            watch_timeout: @default_watch_timeout,
            initial_delay: @default_initial_delay

  @spec new(keyword()) :: t()
  def new(opts) do
    %__MODULE__{
      resource_version: Keyword.get(opts, :resource_version, nil),
      watcher: Keyword.get(opts, :watcher, nil),
      buffer: ResponseBuffer.new(),
      client: Keyword.get(opts, :client, K8s.Client),
      connection: Keyword.get_lazy(opts, :connection, fn -> nil end),
      initial_delay: Keyword.get(opts, :initial_delay, @default_initial_delay),
      watch_timeout: Keyword.get(opts, :watch_timeout, @default_watch_timeout)
    }
  end

  @spec metadata(t()) :: map()
  def metadata(%__MODULE__{watcher: watcher, resource_version: rv} = _s) do
    %{module: watcher, rv: rv}
  end
end
