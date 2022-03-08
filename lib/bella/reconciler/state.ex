defmodule Bella.Reconciler.State do
  @type t :: %__MODULE__{
          reconciler: Bella.Reconciler,
          frequency: integer(),
          client: module(),
          extra: map(),
          connection: K8s.Conn.t() | nil,
          initial_delay: integer()
        }

  @default_frequency 30 * 1000
  @default_initial_delay 500

  defstruct client: nil,
            connection: nil,
            reconciler: nil,
            extra: %{},
            frequency: @default_frequency,
            initial_delay: @default_initial_delay

  @spec new(keyword()) :: t()
  def new(opts) do
    conn_func = Keyword.get(opts, :connection_func, fn -> nil end)
    conn = Keyword.get_lazy(opts, :connection, conn_func)

    %__MODULE__{
      client: Keyword.get(opts, :client, K8s.Client),
      reconciler: Keyword.get(opts, :reconciler, nil),
      extra: Keyword.get(opts, :extra, %{}),
      frequency: Keyword.get(opts, :frequency, @default_frequency),
      initial_delay: Keyword.get(opts, :initial_delay, @default_initial_delay),
      connection: conn
    }
  end

  @spec metadata(t()) :: map()
  def metadata(%__MODULE__{reconciler: reconciler} = _state) do
    %{module: reconciler}
  end
end
