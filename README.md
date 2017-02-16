# ExWss

Elixir Websocket server using, plug and cowboy.

Built because I wanted hands on experience implementing a websocket server in Elixir
without using Phoenix.

## Installation
Requires Elixir >= 1.4.0

```bash
git clone https://github.com/drowzy/ex_wss

```

## Usage

Run with:

```bash
iex -S mix
```

The HTTP server is listening on port 4444 by default. The websocket endpoint is located at ws://localhost:4444/ws
Connected clients are closed if inactive longer than 60s. This can be changed in `config/config.exs` together with `port` and `ws_endpoint`.

This implementation specifies a simple pubsub protocol where the client can subscribe to a topic and broadcast messages to a topic.

### Subscribing

A subscription to a topic can be done by sending a message on the form:

```json
{
  "type": "subscribe",
  "topic": "foo.bar"
}
```
The message is either acked or nacked depending on outcome. Trying to subscribe to the same topic twice will result in a nack the second time.

### Publishing
A Publish is done by sending:

```json
{
  "type": "publish",
  "topic": "foo.bar",
  "payload": "baz"
}
```

The message will be broadcasted to all subscribers on the topic, the request will always be acked.
