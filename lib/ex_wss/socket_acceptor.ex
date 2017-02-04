defmodule ExWss.SocketAcceptor do

  @behaviour :cowboy_websocket_handler

  @registry_name :subscription_registry

  def init(_, req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  #Called on websocket connection initialization.
  def websocket_init(_type, req, opts) do
    timeout = Keyword.get(opts, :timeout)
    registry_key = Keyword.get(opts, :registry_key)
    state = %{registry_key: registry_key}

    {:ok, req, state, timeout}
  end

  # Handle 'ping' messages from the browser - reply
  def websocket_handle({:text, "ping"}, req, state) do
    {:reply, {:text, "pong"}, req, state}
  end

  def websocket_handle({:text, "register"}, req, state) do
    {:reply, {:text, try_register()}, req, state}
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
    {:reply, {:text, message}, req, state}
  end

  # No matter why we terminate, remove all of this pids subscriptions
  def websocket_terminate(reason, _req, _state) do
    IO.puts("terminated")
    IO.puts(reason)
    :ok
  end

  defp try_register() do
    case Registry.register(@registry_name, "sub", []) do
      {:ok, _} -> "registred"
      _ -> "Already registred"
    end
  end

end
