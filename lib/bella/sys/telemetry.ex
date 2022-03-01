defmodule Bella.Telemetry do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      Module.register_attribute(__MODULE__, :events, accumulate: true, persist: false)

      import Bella.Telemetry
      @name opts[:name]
      @metadata opts[:metadata] || %{}
      @before_compile Bella.Telemetry

      @doc false
      def metadata, do: @metadata

      @doc false
      def metadata(alt), do: Map.merge(metadata(), alt)
    end
  end

  defmacro __before_compile__(env) do
    events = Module.get_attribute(env.module, :events)

    quote bind_quoted: [events: events] do
      @doc false
      def events, do: unquote(events)
    end
  end

  defmacro defevent(arg_or_args) do
    names = event_names(arg_or_args)
    function_name = Enum.join(names, "_")

    quote do
      @event [@name | unquote(names)]
      @events @event

      # credo:disable-for-next-line
      def unquote(:"#{function_name}")(measurements, metadata \\ %{}) do
        :telemetry.execute(@event, measurements, metadata(metadata))
        :ok
      end
    end
  end

  defp event_names(arg) when is_list(arg), do: arg
  defp event_names(arg), do: [arg]
end
