defmodule KaqibotTest do
  use ExUnit.Case
  doctest Kaqibot

  test "greets the world" do
    assert Kaqibot.hello() == :world
  end
end
