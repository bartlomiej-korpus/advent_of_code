defmodule Images do
  @width 25
  @height 6

  @input File.read!("./input.txt")
         |> String.split("")
         |> Enum.filter(&(&1 != ""))
         |> Enum.map(&String.to_integer/1)
         |> Enum.chunk_every(@width * @height)

  def solve() do
    Enum.zip(@input)
    |> Enum.map(fn pixels ->
      pixels = Tuple.to_list(pixels)
      Enum.find(pixels, 0, &(&1 != 2))
    end)
    |> Enum.chunk_every(@width)
  end
end

Images.solve()
|> Enum.map(fn row ->
  Enum.map_join(row, "", fn
    0 -> "█"
    1 -> " "
  end)
end)
|> Enum.join("\n")
|> IO.puts()
