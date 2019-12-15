defmodule AirQualityMonitorUiWeb.PageController do
  use AirQualityMonitorUiWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
