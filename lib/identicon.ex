defmodule Identicon do
  @moduledoc """
    Turns a string into a GitHub-like identicon using md5 hashing and
    Erlang's egd library
  """
  alias Identicon.Image
  alias Identicon.Color

  @doc """
    Returns a png image as binary representing the identicon
    corresponding to the input_string
  """
  def main(input_string) do
    input_string
    |> hash_string()
    |> pick_color()
    |> get_colored_indices()
    |> generate_image()
  end

  def hash_string(input_string) do
    binary_hash = :crypto.hash(:md5, input_string)

    list_of_numbers =
      binary_hash
      |> :binary.bin_to_list()

    %Identicon.Image{hex_values: list_of_numbers}
  end

  def pick_color(%Image{hex_values: [r, g, b | _rest]} = image) do
    %Image{image | color: %Color{red: r, green: g, blue: b}}
  end

  def get_colored_indices(%Image{hex_values: hex} = image) do
    mirror_row = fn row ->
      [tail | heads] = Enum.reverse(row)
      heads ++ [tail | Enum.reverse(heads)]
    end

    grid =
      hex
      |> Enum.chunk_every(3, 3, :discard)
      |> Enum.map(mirror_row)
      |> List.flatten()
      |> Enum.with_index()

    indices =
      grid
      |> Enum.filter(fn tuple -> rem(elem(tuple, 0), 2) == 0 end)
      |> Enum.map(fn tuple -> elem(tuple, 1) end)

    %Image{image | colored_indices: indices}
  end

  def generate_image(
        %Image{
          colored_indices: indices,
          color: %Color{red: r, green: g, blue: b}
        } = image
      ) do
    canvas = :egd.create(300, 300)
    color = :egd.color({r, g, b, 1})

    Enum.each(indices, fn index ->
      y_origin = 60 * div(index, 5)
      x_origin = 60 * rem(index, 5)

      :egd.filledRectangle(
        canvas,
        {x_origin, y_origin},
        {x_origin + 60, y_origin + 60},
        color
      )
    end)

    binary = :egd.render(canvas)
    :egd.destroy(canvas)
    %Image{image | binary: binary}
  end

  def save_image(%Image{binary: binary}, path) do
    File.write(path, binary)
  end
end
