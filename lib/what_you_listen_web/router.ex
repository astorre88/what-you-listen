defmodule WhatYouListenWeb.Router do
  use WhatYouListenWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", WhatYouListenWeb do
    pipe_through :api

    resources("/images", ImageController, only: [:create])
  end
end
