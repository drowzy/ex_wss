defmodule ExWss.PubSub do
  def subscribe(topic, registry_key) do
    case Registry.register(registry_key, topic, []) do
      {:ok, _} -> ack()
      _ -> nack()
    end
  end

  def publish({topic, payload}, from, registry_key) do
    Registry.dispatch(registry_key, topic, fn entries ->
      for {p, _} <- entries, p != from, do: send(p, {:broadcast, payload})
    end)

    ack()
  end

  defp ack do
    %{type: "ack"}
  end

  defp nack do
    %{type: "nack"}
  end

end
