defmodule WhatYouListen.Mq.FeedListener do
  @moduledoc """
  Feed service events listener.
  Provides input/output queues managing.
  """

  use AMQP
  use GenServer

  alias AMQP.Channel
  alias WhatYouListen.Images.Recognize, as: RecognizeText
  alias WhatYouListen.Mq.Conn
  alias WhatYouListen.Tracks.RateLimiter

  require Logger

  @queue "what_you_listen_input_request"

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    send(self(), :connect)
    {:ok, nil}
  end

  def handle_info(:connect, _) do
    with {:ok, conn} <- Conn.get_connection(),
         {:ok, channel} <- Channel.open(conn),
         :ok <- declare(channel) do
      Conn |> GenServer.whereis() |> Process.monitor()
      {:noreply, channel}
    else
      _ ->
        Process.send_after(self(), :connect, 1_000)
        {:noreply, nil}
    end
  end

  def handle_info({:DOWN, _, _, _, _}, state) do
    close(state)
    Process.send_after(self(), :connect, 100)
    {:noreply, nil}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, state) do
    {:noreply, state}
  end

  def handle_info(
        {:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}},
        state
      ) do
    # You might want to run payload consumption in separate Tasks in production
    consume(tag, redelivered, payload, state)
    {:noreply, state}
  end

  defp consume(tag, redelivered, payload, channel) do
    case Jason.decode(payload) do
      {:ok,
       %{
         "url" => url,
         "post_id" => post_id,
         "group_id" => group_id,
         "main_language" => main_language
       }} ->
        Logger.info("Retry recognize with rus+eng")
        recognize(url, channel, tag, post_id, group_id, main_language)

      {:ok, %{"url" => url, "post_id" => post_id, "group_id" => group_id}} ->
        recognize(url, channel, tag, post_id, group_id)

      _ ->
        :ok = Basic.reject(channel, tag, requeue: false)
        Logger.error("Unacceptable payload: #{payload}")
    end
  rescue
    error ->
      :ok = Basic.reject(channel, tag, requeue: not redelivered)
      Logger.error("Error converting payload: #{inspect(error)}")
  end

  defp recognize(url, channel, tag, post_id, group_id, main_language \\ "eng") do
    case RecognizeText.call(%{"path" => url}, main_language) do
      {:ok, text} ->
        :ok = Basic.ack(channel, tag)

        RateLimiter.make_request(url, text, post_id, group_id, channel,
          last_attempt: main_language == "rus"
        )

      :error ->
        case main_language do
          "eng" ->
            Logger.info("RecognizeText RESPONSE: no matches")
            recognize(url, channel, tag, post_id, group_id, "rus")

          _ ->
            :ok = Basic.reject(channel, tag, requeue: false)
            Logger.info("All full-cycle attempts are exhausted")
        end

      error ->
        :ok = Basic.reject(channel, tag, requeue: false)
        Logger.error("RecognizeText error: #{inspect(error)}")
    end
  end

  defp declare(channel) do
    {:ok, _} = Queue.declare(channel, @queue, durable: true, arguments: [])
    :ok = Basic.qos(channel, prefetch_count: 100)
    {:ok, _consumer_tag} = Basic.consume(channel, @queue)
    :ok
  rescue
    _ ->
      close(channel)
      :error
  end

  defp close(nil), do: :ok

  defp close(channel) do
    Channel.close(channel)
  rescue
    _ -> :ok
  end
end
