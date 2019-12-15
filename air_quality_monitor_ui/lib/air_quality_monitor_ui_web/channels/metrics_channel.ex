defmodule AirQualityMonitorUiWeb.MetricsChannel do
  use AirQualityMonitorUiWeb, :channel

  def join("metrics:lobby", _payload, socket) do
    {:ok, socket}
  end
end
