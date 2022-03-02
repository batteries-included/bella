defmodule Bella.Watcher.ResourceVersionTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Bella.Watcher.ResourceVersion

  test "extract_rv/1 returns the metadata if there" do
    assert "1337" == ResourceVersion.extract_rv(%{"metadata" => %{"resourceVersion" => "1337"}})
  end
end
