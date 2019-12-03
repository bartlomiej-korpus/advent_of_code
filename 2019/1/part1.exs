File.read!("./input.txt")
|> String.split("\n")
|> Enum.map(&String.to_integer/1)
|> Enum.map(fn mass ->
  Float.floor((mass / 3)) - 2
end)
|> Enum.sum()
|> IO.inspect()
