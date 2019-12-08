defmodule Images do
  @width 25
  @height 6

  @input File.read!("./input.txt")
  |> String.split("")
  |> Enum.filter(& &1 != "")
  |> Enum.map(&String.to_integer/1)
  |> Enum.chunk_every(@width*@height)
  # |> Enum.map(fn layer ->
  #   Enum.chunk_every(layer, @width)
  # end)

  def solve() do
    layer = @input
    |> Enum.min_by(fn layer ->
      Enum.count(layer, & &1 == 0)
    end)

    layer_ones = Enum.count(layer, & &1 == 1)
    layer_twos = Enum.count(layer, & &1 == 2)

    layer_ones * layer_twos
  end

end

Images.solve()
|> IO.inspect
