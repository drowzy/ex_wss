defmodule ExWss.SocketAcceptor do

  @behaviour :cowboy_websocket_handler
  @sub_type "subscribe"
  @pub_type "publish"

  def init(_, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  # Called on websocket connection initialization.
  def websocket_init(_type, req, opts) do
    timeout      = Keyword.get(opts, :timeout)
    registry_key = Keyword.get(opts, :registry_key)
    state        = %{registry_key: registry_key}
    # This is a good place to negotiate protocols, authenticate etc.
    {:ok, req, state}
  end

  # Respond to ping
  def websocket_handle({:text, "ping"}, req, state) do
    {:reply, {:text, "pong"}, req, state}
  end

  # Handle messages from client, either we subscribe, or publish.
  # The result is a nack or ack depending on outcome.
  def websocket_handle({:text, content}, req, %{registry_key: registry_key} = state) do
    %{"type" => type, "topic" => topic } = msg = (content |> Poison.decode!)
    resp = case type do
             @sub_type -> ExWss.PubSub.subscribe(topic, registry_key)
             @pub_type -> ExWss.PubSub.publish({topic, Map.get(msg, "payload")}, self(), registry_key)
             _ -> %{type: "nack"}
           end
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
  def websocket_terminate(_reason, _req, _state) do
    :ok
  end
end
