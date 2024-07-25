defmodule LiveFlopTest do
  use ExUnit.Case
  doctest LiveFlop

  test "greets the world" do
    assert LiveFlop.hello() == :world
  end
end
