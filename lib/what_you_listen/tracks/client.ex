defmodule WhatYouListen.Tracks.Client do
  @moduledoc """
  Behaviour for track search service API client.
  """

  @callback request(service_path :: String.t(), options :: [stream: nonempty_charlist()]) ::
              map() | :ok | {:error, atom()}
end
