defmodule WhatYouListen.Tracks.Clients.Stub do
  @moduledoc """
  HTTP stub-client.
  """

  @behaviour WhatYouListen.Tracks.Client

  def request(url, options \\ [])

  def request("https://music-api.com", _) do
    %{"data" => %{"title" => "Minor Swing", "artist" => %{"name" => "Django Reinhardt"}}}
  end

  def request("https://image-resource.com", _) do
    :ok
  end

  def request(_, _) do
    {:error, :internal_server_error}
  end
end
