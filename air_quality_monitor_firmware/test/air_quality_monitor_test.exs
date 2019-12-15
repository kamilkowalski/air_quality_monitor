defmodule AirQualityMonitorTest do
  use ExUnit.Case
  doctest AirQualityMonitor

  test "greets the world" do
    assert AirQualityMonitor.hello() == :world
  end
end
