defmodule AirQualityMonitor.Monitor do
  use GenServer
  require Logger

  @baud_rate 9600
  @port_name "ttyAMA0"

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  @impl true
  def init(_arg) do
    {:ok, uart_pid} = Circuits.UART.start_link()
    :ok = Circuits.UART.open(uart_pid, @port_name, speed: @baud_rate, active: false)
    Process.send_after(self(), :read_metrics, 5000)
    {:ok, uart_pid}
  end

  @impl true
  def handle_info(:read_metrics, uart_pid) do
    {:ok, message} = Circuits.UART.read(uart_pid, 5000)

    case parse_message(message) do
      {:ok, metrics} -> send_update(metrics)
      {:error, error} -> Logger.info(error)
    end

    Process.send_after(self(), :read_metrics, 5000)
    {:noreply, uart_pid}
  end

  defp parse_message(message) do
    with <<0x42, 0x4D, _padding::binary-size(8), data::binary-size(6), _rest::binary>> <- message,
         <<pm1::binary-size(2), pm25::binary-size(2), pm10::binary-size(2)>> <- data do
      metrics = %{
        pm1: :binary.decode_unsigned(pm1),
        pm25: :binary.decode_unsigned(pm25),
        pm10: :binary.decode_unsigned(pm10)
      }

      {:ok, metrics}
    else
      _ -> {:error, :invalid_message}
    end
  end

  defp send_update(metrics) do
    Logger.info(inspect(metrics))
    AirQualityMonitorUiWeb.Endpoint.broadcast!("metrics:lobby", "metrics_update", metrics)
  end
end
