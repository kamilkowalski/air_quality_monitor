defmodule AirQualityMonitor.Monitor do
  use GenServer
  require Logger

  @baud_rate 9600
  @port_name "ttyAMA0"
  @measurement_frequency 5000
  @measurement_timeout 5000

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  @impl true
  def init(_arg) do
    {:ok, uart_pid} = Circuits.UART.start_link()

    :ok =
      Circuits.UART.open(uart_pid, @port_name,
        speed: @baud_rate,
        active: false,
        framing: CircuitsUARTFramingPMS7003
      )

    :timer.send_interval(@measurement_frequency, :read_metrics)

    {:ok, uart_pid}
  end

  @impl true
  def handle_info(:read_metrics, uart_pid) do
    {:ok, measurement} = Circuits.UART.read(uart_pid, @measurement_timeout)

    case measurement do
      %CircuitsUARTFramingPMS7003.Measurement{} -> send_update(measurement)
      _ -> Logger.info("ERROR - Received unknown measurement data: '#{inspect(measurement)}'")
    end

    {:noreply, uart_pid}
  end

  defp send_update(metrics) do
    Logger.info(inspect(metrics))
    AirQualityMonitorUiWeb.Endpoint.broadcast!("metrics:lobby", "metrics_update", metrics)
  end
end
