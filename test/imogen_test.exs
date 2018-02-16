defmodule ImogenTest do
  use ExUnit.Case
  doctest Imogen

  test "greets the world" do
    assert Imogen.hello() == :world
  end
end
