defmodule Orbits do
  @input File.read!("./input.txt")
  |> String.split("\n")
  |> Enum.map(& String.split(&1, ")"))
  |> Enum.map(&List.to_tuple/1)

  def solve() do
    build_tree("COM", @input)
    |> traverse_count()
  end

  def build_tree(object, pairs) do
    %{
      object: object,
      orbiters: pairs
        |> Enum.filter(& elem(&1, 0) == object)
        |> Enum.map(& build_tree(elem(&1, 1), pairs))
    }
  end

  def traverse_count(tree, indir \\ 0) do
    indir + (Enum.map(tree.orbiters, & traverse_count(&1, indir + 1)) |> Enum.sum() )
  end

end

Orbits.solve()
|> IO.inspect
