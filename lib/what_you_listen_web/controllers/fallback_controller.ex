defmodule WhatYouListenWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use WhatYouListenWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(WhatYouListenWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :bad_request}) do
    conn
    |> put_status(:bad_request)
    |> put_view(WhatYouListenWeb.ErrorView)
    |> render(:"400")
  end

  def call(conn, {:error, {:bad_request, errors}}) when is_map(errors) do
    conn
    |> put_status(:bad_request)
    |> json(%{"errors" => errors})
  end

  def call(conn, {:error, :internal_server_error}) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(WhatYouListenWeb.ErrorView)
    |> render(:"500")
  end
end
