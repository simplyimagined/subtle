defmodule SubtleTest do
  use ExUnit.Case
  doctest Subtle

  test "greets the world" do
    assert Subtle.hello() == :world
  end
end
