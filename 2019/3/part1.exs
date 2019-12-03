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
    [positions1, positions2] = @input
    |> Enum.map(fn wire_moves ->
      Enum.reduce(wire_moves, {{0,0}, []}, fn command, {current_pos, positions} ->
        new_pos = do_move(command, current_pos)

        {new_pos, move_to_positions(current_pos, new_pos) ++ positions}
      end)
    end)
    |> Enum.map(fn {_, positions} -> MapSet.new(positions) end)


    MapSet.intersection(positions1, positions2)
    |> Enum.filter(& &1 != {0, 0})
    |> Enum.map(&manhattan_to_center/1)
    |> Enum.min()

  end

  def do_move({:up, distance}, {x, y}), do: {x, y + distance}
  def do_move({:down, distance}, {x, y}), do: {x, y - distance}
  def do_move({:left, distance}, {x, y}), do: {x - distance, y}
  def do_move({:right, distance}, {x, y}), do: {x + distance, y}

  def move_to_positions({x1, y1}, {x2, y2}) do
    for x <- x1..x2, y<-y1..y2 do
      {x, y}
    end
    |> Enum.reverse()
  end

  def manhattan_to_center({x, y}), do: abs(x) + abs(y)

end

Wires.solve()
|> IO.inspect
