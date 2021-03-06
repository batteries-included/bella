defmodule Bella.Watcher.ResourceVersion do
  @moduledoc "Get the resourceVersion for a `K8s.Operation`"

  @spec extract_rv(map()) :: binary() | {:gone, binary()} | {:error, binary()}
  def extract_rv(%{"metadata" => %{"resourceVersion" => rv}}), do: rv
  def extract_rv(%{"message" => message}), do: {:gone, message}
  def extract_rv(_), do: {:error, "cant extract rv"}
end
