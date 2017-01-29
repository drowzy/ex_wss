defmodule ExWss.Router do
  use Plug.Router
  plug Plug.Logger

  plug :match
  plug :dispatch

  match _ do
    send_resp(conn, 200, "ok")
  end
end
