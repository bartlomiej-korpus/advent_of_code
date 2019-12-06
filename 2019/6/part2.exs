defmodule Orbits do
  @input File.read!("./input.txt")
  |> String.split("\n")
  |> Enum.map(& String.split(&1, ")"))
  |> Enum.map(&List.to_tuple/1)

  def solve() do
    build_adjacencies(@input)
    |> count_hops("YOU", "SAN")
    |> Kernel.-(2)
  end

  def build_adjacencies(pairs) do
    pairs
    |> Enum.reduce(%{}, fn {a, b}, adj ->
      adj
      |> put_in([a], MapSet.put(Map.get(adj, a, MapSet.new()), b))
      |> put_in([b], MapSet.put(Map.get(adj, b, MapSet.new()), a))
    end)
  end

  def count_hops(adjacencies, from, to, previous \\ nil) do
    left_to_visit = MapSet.delete(adjacencies[from], previous)
    is_dest = from == to
    result = left_to_visit
      |> Enum.map(& count_hops(adjacencies, &1, to, from))
      |> Enum.find(& &1 != nil)

    case {result, is_dest} do
      {_, true} -> 0
      {nil, _} -> nil
      {num, _} -> 1 + num
    end
  end

end

Orbits.solve()
|> IO.inspect
