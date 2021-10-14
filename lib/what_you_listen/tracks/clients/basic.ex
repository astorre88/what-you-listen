defmodule WhatYouListen.Tracks.Clients.Basic do
  @moduledoc """
  Track search service API client.
  """

  @behaviour WhatYouListen.Tracks.Client

  require Logger

  def request(url, options \\ []) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    case :httpc.request(:get, {String.to_charlist(url), []}, [], options) do
      {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} ->
        body
        |> to_string
        |> Jason.decode()
        |> case do
          {:ok, response} -> response
          _ -> {:error, :internal_server_error}
        end

      {:ok, :saved_to_file} ->
        :ok

      error ->
        Logger.error("HTTP REQUEST ERROR: #{inspect(error)}")
        {:error, :internal_server_error}
    end
  end
end
