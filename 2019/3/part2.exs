defmodule Wires do
  @input File.read!("./input.txt")
  |> String.split("\n")
  |> Enum.map(fn str_path ->
    str_path
    |> String.split(",")
    |> Enum.map(fn command ->
      String.split_at(command, 1)
    end)
    |> Enum.map(fn
      {"U", dist} -> {:up, dist}
      {"D", dist} -> {:down, dist}
      {"L", dist} -> {:left, dist}
      {"R", dist} -> {:right, dist}
    end)
    |> Enum.map(fn {direction, distance} ->
      {direction, String.to_integer(distance)}
    end)
  end)

  def solve() do
    positions= @input
    |> Enum.map(fn wire_moves ->
      Enum.reduce(wire_moves, {{0,0}, []}, fn command, {current_pos, positions} ->
        new_pos = do_move(command, current_pos)

        {new_pos, move_to_positions(current_pos, new_pos) ++ positions}
      end)
    end)
    |> Enum.map(fn {_, positions} -> Enum.reverse(positions) end)


    calculate_intersections(positions)
    |> Enum.map(fn intersection_position ->
      {intersection_position,
      Enum.map(positions, fn wire_positions ->
        Enum.find_index(wire_positions, & &1 == intersection_position) + 1
      end)
      |> Enum.sum()}
    end)
    |> Enum.min_by(fn {_, dist} -> dist end)
  end

  def calculate_intersections(positions) do
    [positions1, positions2] = positions

    MapSet.intersection(MapSet.new(positions1), MapSet.new(positions2))
  end

  def do_move({:up, distance}, {x, y}), do: {x, y + distance}
  def do_move({:down, distance}, {x, y}), do: {x, y - distance}
  def do_move({:left, distance}, {x, y}), do: {x - distance, y}
  def do_move({:right, distance}, {x, y}), do: {x + distance, y}

  def move_to_positions({x1, y1}, {x2, y2}) do
    for x <- x1..x2, y<-y1..y2 do
      {x, y}
    end
    |> Enum.drop(1)
    |> Enum.reverse()
  end

end

Wires.solve()
|> IO.inspect
