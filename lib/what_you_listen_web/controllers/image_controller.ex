defmodule WhatYouListenWeb.ImageController do
  use WhatYouListenWeb, :controller

  alias WhatYouListen.Images.Recognize, as: RecognizeText

  action_fallback WhatYouListenWeb.FallbackController

  def create(conn, %{"image" => image_params}) do
    with {:ok, text} <- RecognizeText.call(image_params, "eng") do
      conn
      |> put_status(:created)
      |> render("show.json", text: text)
    end
  end
end
