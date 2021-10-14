defmodule WhatYouListen.Tracks.Action do
  @moduledoc """
  The `using` for the wrapping HTTP-requests.

  ## Example

  You can create the wrapper around `SomeAction` service.
  It returns raw HTTP-request result.

  ```elixir
  defmodule WhatYouListen.Tracks.Actions.SomeAction do
    use WhatYouListen.Tracks.Action

    def call(url) do
      @http_client.request(url)
    end
  end
  ```
  """

  @doc """
  The macros which creates helper module attribute:

  * `@http_client` - used realization of `WhatYouListen.Tracks.Client`
  """
  defmacro __using__(_opts) do
    http_client = Application.fetch_env!(:what_you_listen, __MODULE__)[:client]

    quote location: :keep, bind_quoted: [http_client: http_client] do
      @behaviour WhatYouListen.Tracks.Action

      @http_client http_client
    end
  end
end
