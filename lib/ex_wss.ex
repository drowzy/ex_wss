defmodule ExWss do
  use Application

  @registry_key :subscriptions

  def start(_type, _args) do
    import Supervisor.Spec

    port        = Application.get_env(:ex_wss, :port, 8888)
    timeout     = Application.get_env(:ex_wss, :timeout, 60000)
    ws_endpoint = Application.get_env(:ex_wss, :ws_endpoint, "ws")

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, ExWss.Router, [], [dispatch: dispatch(ws_endpoint, timeout), port: port ]),
      supervisor(Registry, [:unique, @registry_key])
    ]

    opts = [strategy: :one_for_one, name: ExWss.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch(endpoint, timeout) do
    [
      {:_, [
          {"/#{endpoint}", ExWss.SocketAcceptor, [
              timeout: timeout,
              registry_key: @registry_key
            ]},
          {:_, Plug.Adapters.Cowboy.Handler, {ExWss.Router, []}}
        ]
      }
    ]
  end
end
