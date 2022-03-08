defmodule Bella.Watcher.State do
  @moduledoc "State of the Watcher"

  alias Bella.Watcher.ResponseBuffer

  @type t :: %__MODULE__{
          watcher: Bella.Watcher,
          buffer: ResponseBuffer.t(),
          resource_version: String.t() | nil,
          k8s_watcher_ref: reference() | nil,
          extra: map(),
          client: module(),
          connection: K8s.Conn.t() | nil,
          initial_delay: integer()
        }

  @default_initial_delay 500
  @default_watch_timeout 64_000

  defstruct client: nil,
            connection: nil,
            watcher: nil,
            k8s_watcher_ref: nil,
            buffer: nil,
            resource_version: nil,
            extra: %{},
            watch_timeout: @default_watch_timeout,
            initial_delay: @default_initial_delay

  @spec new(keyword()) :: t()
  def new(opts) do
    conn_func = Keyword.get(opts, :connection_func, fn -> nil end)
    conn = Keyword.get_lazy(opts, :connection, conn_func)

    %__MODULE__{
      k8s_watcher_ref: nil,
      buffer: ResponseBuffer.new(),
      resource_version: Keyword.get(opts, :resource_version, nil),
      watcher: Keyword.get(opts, :watcher, nil),
      client: Keyword.get(opts, :client, K8s.Client),
      extra: Keyword.get(opts, :extra, %{}),
      initial_delay: Keyword.get(opts, :initial_delay, @default_initial_delay),
      watch_timeout: Keyword.get(opts, :watch_timeout, @default_watch_timeout),
      connection: conn
    }
  end

  @spec metadata(t()) :: map()
  def metadata(%__MODULE__{watcher: watcher, resource_version: rv, k8s_watcher_ref: ref} = _s) do
    %{module: watcher, rv: rv, is_watcher_active: ref != nil}
  end
end
