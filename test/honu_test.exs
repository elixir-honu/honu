defmodule HonuTest do
  use ExUnit.Case
  doctest Honu

  test "greets the world" do
    assert Honu.hello() == :world
  end
end
