defmodule WhatYouListen.Tracks.RateLimiter do
  @moduledoc """
  RateLimiter API.
  """

  use AMQP
  use GenServer
  use WhatYouListen.Tracks.Action

  require Logger

  @music_service Application.get_env(:what_you_listen, :music_service)

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    state = %{
      requests_per_timeframe: get_requests_per_timeframe(),
      available_tokens: get_requests_per_timeframe(),
      token_refresh_rate: calculate_refresh_rate(),
      request_queue: :queue.new(),
      request_queue_size: 0,
      send_after_ref: nil
    }

    {:ok, state, {:continue, :initial_timer}}
  end

  def make_request(image_path, text, post_id, group_id, channel, options) do
    GenServer.cast(
      __MODULE__,
      {:enqueue_request, {image_path, text, post_id, group_id, channel, options}}
    )
  end

  @impl true
  def handle_continue(:initial_timer, state) do
    {:noreply, %{state | send_after_ref: schedule_timer(state.token_refresh_rate)}}
  end

  @impl true
  def handle_cast(
        {:enqueue_request, {image_path, text, post_id, group_id, channel, options}},
        %{available_tokens: 0} = state
      ) do
    updated_queue =
      :queue.in({image_path, text, post_id, group_id, channel, options}, state.request_queue)

    new_queue_size = state.request_queue_size + 1

    {:noreply, %{state | request_queue: updated_queue, request_queue_size: new_queue_size}}
  end

  @impl true
  def handle_cast(
        {:enqueue_request, {image_path, text, post_id, group_id, channel, options}},
        state
      ) do
    async_task_request(image_path, text, post_id, group_id, channel, options)

    {:noreply, %{state | available_tokens: state.available_tokens - 1}}
  end

  @impl true
  def handle_info(:token_refresh, %{request_queue_size: 0} = state) do
    token_count =
      if state.available_tokens < state.requests_per_timeframe do
        state.available_tokens + 1
      else
        state.available_tokens
      end

    {:noreply,
     %{
       state
       | send_after_ref: schedule_timer(state.token_refresh_rate),
         available_tokens: token_count
     }}
  end

  @impl true
  def handle_info(:token_refresh, state) do
    {{:value, {image_path, text, post_id, group_id, channel, options}}, new_request_queue} =
      :queue.out(state.request_queue)

    async_task_request(image_path, text, post_id, group_id, channel, options)

    {:noreply,
     %{
       state
       | request_queue: new_request_queue,
         send_after_ref: schedule_timer(state.token_refresh_rate),
         request_queue_size: state.request_queue_size - 1
     }}
  end

  def handle_info({ref, _result}, state) do
    Process.demonitor(ref, [:flush])

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:noreply, state}
  end

  defp async_task_request(image_path, text, post_id, group_id, channel, options) do
    Logger.info(text)

    Task.Supervisor.async_nolink(__MODULE__.TaskSupervisor, fn ->
      case text
           |> compile_url()
           |> @http_client.request()
           |> Map.get("data") do
        [] ->
          Logger.info("API RESPONSE: no matches")
          send_retry(image_path, post_id, group_id, channel, options)

        [item | _] ->
          with {:ok, artist} <- Map.fetch(item, "artist"),
               {:ok, artist_name} <- Map.fetch(artist, "name"),
               {:ok, track} <- Map.fetch(item, "title"),
               {:ok, message} <-
                 Jason.encode(%{
                   artist: artist_name,
                   track: track,
                   post_id: post_id,
                   group_id: group_id
                 }) do
            Logger.info(message)
            Basic.publish(channel, "", "what_you_listen_output_request", message, [])
          else
            error ->
              Logger.error("PARSE TRACK ERROR: #{inspect(error)}")
          end

        error ->
          Logger.error("API RESPONSE ERROR: #{inspect(error)}")
      end
    end)
  end

  defp send_retry(_, _, _, _, last_attempt: true),
    do: Logger.info("All full-cycle attempts are exhausted")

  defp send_retry(image_path, post_id, group_id, channel, last_attempt: false) do
    Logger.info("Retrying with 'rus' primary")

    with {:ok, message} <-
           Jason.encode(%{
             url: image_path,
             post_id: post_id,
             group_id: group_id,
             main_language: "rus"
           }) do
      Basic.publish(channel, "", "what_you_listen_input_request", message, [])
    end
  end

  defp compile_url(text) do
    @music_service[:url]
    |> URI.parse()
    |> URI.merge("search")
    |> URI.merge("?q=#{URI.encode_www_form(text)}")
    |> to_string()
  end

  defp schedule_timer(token_refresh_rate) do
    Process.send_after(self(), :token_refresh, token_refresh_rate)
  end

  defp get_requests_per_timeframe, do: get_rate_limiter_config(:timeframe_max_requests)
  defp get_timeframe, do: get_rate_limiter_config(:timeframe)

  defp calculate_refresh_rate do
    floor(:timer.seconds(get_timeframe()) / get_requests_per_timeframe())
  end

  defp get_rate_limiter_config(config) do
    :what_you_listen
    |> Application.get_env(RateLimiter)
    |> Keyword.get(config)
  end
end
