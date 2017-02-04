defmodule ExWss.SocketAcceptor do

  @behaviour :cowboy_websocket_handler

  def init(_, req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  #Called on websocket connection initialization.
  def websocket_init(_type, req, opts) do
    timeout = Keyword.get(opts, :timeout)
    registry_key = Keyword.get(opts, :registry_key)
    state = %{registry_key: registry_key}

    IO.puts("Connected client #{Kernel.inspect(self())}")

    {:ok, req, state}
  end

  # Handle 'ping' messages from the browser - reply
  def websocket_handle({:text, "ping"}, req, state) do
    {:reply, {:text, "pong"}, req, state}
  end

  # Handle other messages from client, either we
  # subscribe, or publish
  def websocket_handle({:text, content}, req, state) do
    resp = content
    |> Poison.decode!
    |> action(state)
    |> Poison.encode!

    {:reply, {:text, resp}, req, state}
  end

  # Messages received through the info callback are from
  # other elixir processes, for instance when a publish
  # is performed on a topic this process subscribes on
  # we send the messge to the client
  def websocket_info({:broadcast, message}, req, state) do
    {:reply, {:text, message}, req, state}
  end

  # No matter why we terminate, remove all of this pids subscriptions
  def websocket_terminate(reason, _req, _state) do
    :ok
  end

  defp action(msg = %{"type" => "subscribe"}, %{registry_key: registry_key}) do
    case Registry.register(registry_key, Map.get(msg, :topic), []) do
      {:ok, _} -> ack()
      _ -> nack()
    end
  end

  defp action(msg = %{"type" => "publish", "payload" => payload}, %{registry_key: registry_key}) do
    pid = self()

    Registry.dispatch(registry_key, Map.get(msg, :topic), fn entries ->
      for {p, _} <- entries, p != pid, do: send(p, {:broadcast, payload})
    end)

    ack()
  end

  defp action(_) do
    nack()
  end

  defp ack do
    %{type: "ack"}
  end

  defp nack do
    %{type: "nack"}
  end

end
