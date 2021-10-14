defmodule WhatYouListen.Mq.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    [
      WhatYouListen.Mq.Conn,
      WhatYouListen.Mq.FeedListener
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
