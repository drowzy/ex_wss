defmodule ExWss do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, ExWss.Router, [], [dispatch: dispatch(), port: 4444]),
      supervisor(Registry, [:unique, :subscription_registry])
    ]

    opts = [strategy: :one_for_one, name: ExWss.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_, [
          {"/ws", ExWss.SocketAcceptor, []},
          {:_, Plug.Adapters.Cowboy.Handler, {ExWss.Router, []}}
        ]
      }
    ]
  end
end
