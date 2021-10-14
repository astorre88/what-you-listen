defmodule WhatYouListen.Images.Recognize do
  @moduledoc """
  Service for text recognition.
  """

  use WhatYouListen.Tracks.Action

  require Logger

  def call(%{"path" => image_path}, main_language)
      when is_binary(image_path) and is_binary(main_language) do
    with {:ok, tmp_file_path} <- prepare_tmp_file(image_path),
         :ok <- @http_client.request(image_path, stream: String.to_charlist(tmp_file_path)),
         {:ok, _} = result <-
           tmp_file_path |> TesseractOcr.read(tesseract_params(main_language)) |> find_phrase() do
      remove_tmp_file(tmp_file_path)
      result
    end
  end

  def call(params, _) do
    {:error, {:bad_request, %{"wrong params" => [params]}}}
  end

  defp tesseract_params("eng" = main_language), do: %{lang: "#{main_language}+rus"}
  defp tesseract_params("rus" = main_language), do: %{lang: "#{main_language}+eng"}

  defp prepare_tmp_file(image_path) when byte_size(image_path) > 0 do
    with filename <- Regex.run(~r/[^\/]+$/, image_path),
         dir when not is_nil(dir) <- System.tmp_dir() do
      {:ok, Path.join(dir, filename)}
    else
      _ ->
        Logger.error("Unable to find writable temporary directory")
        {:error, :internal_server_error}
    end
  end

  defp prepare_tmp_file(_) do
    {:error, {:bad_request, %{"image_path" => ["is empty"]}}}
  end

  defp find_phrase(text) do
    filtered_words =
      ~r/(^|(?<=\n))\w[^\n()]*/u
      |> Regex.scan(text, capture: :first)
      |> Enum.sort(&(max_words_index(&1) >= max_words_index(&2)))
      |> Enum.map(fn [line] -> String.trim(line) end)

    text_words = String.split(text, "\n")

    filtered_words
    |> Enum.with_index(0)
    |> Enum.map(fn {line, filtered_word_index} ->
      {Enum.find_index(text_words, fn word -> String.contains?(word, line) end),
       filtered_word_index}
    end)
    |> Enum.sort()
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.into(%{}, fn [{x_index, _} = x, {y_index, _}] -> {x, x_index - y_index} end)
    |> Enum.filter(fn {_, v} -> v == -1 end)
    |> Enum.sort_by(fn {{recognized_word_index, _}, _} -> recognized_word_index end, :desc)
    |> Enum.map(fn {{recognized_word_index, filtered_word_index}, _} ->
      filtered_word = Enum.at(filtered_words, filtered_word_index)
      text_word = Enum.at(text_words, recognized_word_index + 1)
      clean(filtered_word) <> " " <> clean(text_word)
    end)
    |> Enum.fetch(0)
  end

  defp clean(word) do
    Regex.replace(~r/\b\s\w\b/u, word, "")
  end

  defp max_words_index([line]) do
    words = line |> String.split()
    words_count = words |> length
    chars_count = words |> Enum.reduce(0, fn x, acc -> String.length(x) + acc end)
    chars_count / words_count
  end

  defp remove_tmp_file(tmp_file_path) do
    case File.rm(tmp_file_path) do
      :ok ->
        nil

      {:error, error} ->
        Logger.error("Unable to remove temporary file: #{inspect(error)}")
    end
  end
end
