defmodule ExWss.SocketAcceptor do

  @behaviour :cowboy_websocket_handler

  def init(_, req, _opts) do
    Process.send_after(self(), {:deliver, "foo"}, 1000)
    {:upgrade, :protocol, :cowboy_websocket}
  end

  @timeout 60000 # terminate if no activity for one minute

  #Called on websocket connection initialization.
  def websocket_init(_type, req, _opts) do
    state = %{}
    {:ok, req, state, @timeout}
  end

  # Handle 'ping' messages from the browser - reply
  def websocket_handle({:text, "ping"}, req, state) do
    {:reply, {:text, "pong"}, req, state}
  end

  # Handle other messages from the browser - don't reply
  def websocket_handle({:text, message}, req, state) do
    IO.puts(message)
    {:ok, req, state}
  end

  # Format and forward elixir messages to client
  def websocket_info(message, req, state) when is_binary(message) do
    IO.puts(message)
    {:reply, {:text, message}, req, state}
  end

  def websocket_info({:deliver, message}, req, state) do
    IO.puts("from info")
    IO.puts(message)

    {:reply, {:text, message}, req, state}
  end

  # No matter why we terminate, remove all of this pids subscriptions
  def websocket_terminate(_reason, _req, _state) do
    :ok
  end
end
