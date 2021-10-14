defmodule WhatYouListen.Mq.Conn do
  @moduledoc """
  AMQP connection process.
  """

  use GenServer

  alias AMQP.Connection

  require Logger

  @reconnect_interval 5_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    send(self(), :connect)
    {:ok, nil}
  end

  def get_connection do
    case GenServer.call(__MODULE__, :get) do
      nil -> {:error, :not_connected}
      conn -> {:ok, conn}
    end
  end

  def handle_call(:get, _, conn) do
    {:reply, conn, conn}
  end

  def handle_info(:connect, nil) do
    case connect_mq() do
      {:ok, conn} ->
        # Get notifications when the connection goes down
        Process.monitor(conn.pid)
        {:noreply, conn}

      {:error, _} ->
        Logger.error("Failed to connect RabbitMQ. Reconnecting later...")
        # Retry later
        Process.send_after(self(), :connect, @reconnect_interval)
        {:noreply, nil}
    end
  end

  def handle_info(:connect, conn), do: {:noreply, conn}

  def handle_info({:DOWN, _, :process, _pid, reason}, _) do
    # Stop GenServer. Will be restarted by Supervisor.
    {:stop, {:connection_lost, reason}, nil}
  end

  defp connect_mq do
    with [_ | _] = envs <- Application.get_env(:what_you_listen, :mq),
         host when is_binary(host) <- envs[:host],
         port when is_binary(port) <- envs[:port],
         {port, ""} <- Integer.parse(port),
         user when is_binary(user) <- envs[:user],
         pass when is_binary(pass) <- envs[:pass] do
      Connection.open(host: host, port: port, username: user, password: pass)
    else
      [] -> {:error, "missing all params for mq"}
      nil -> {:error, "missing some params for mq"}
      _ -> {:error, "error in mq connect, seems port"}
    end
  end
end
