defmodule WhatYouListenWeb.ImageView do
  use WhatYouListenWeb, :view
  alias WhatYouListenWeb.ImageView

  def render("index.json", %{images: images}) do
    %{data: render_many(images, ImageView, "image.json")}
  end

  def render("show.json", %{image: image}) do
    %{data: render_one(image, ImageView, "image.json")}
  end

  def render("image.json", %{image: image}) do
    %{id: image.id, text: image.text}
  end
end
