defmodule Asteroids do
  @input File.read!("./input.txt")
         |> String.split("\n")
         |> Enum.with_index()
         |> Enum.flat_map(fn {line, y} ->
           line
           |> String.split("")
           |> Enum.filter(&(&1 != ""))
           |> Enum.with_index()
           |> Enum.filter(&(elem(&1, 0) == "#"))
           |> Enum.map(fn {_, x} ->
             {x, y}
           end)
         end)
         |> MapSet.new()

  @station {37, 25}

  def solve() do
    destroy_until_empty(@input, @station)
    |> Enum.at(199)
  end

  def destroy_until_empty(asteroids, station, destroyed \\ []) do
    detected = detected_from_point_in_order(asteroids, station)

    case detected do
      [] -> Enum.reverse(destroyed)
      _ -> destroy_until_empty((MapSet.to_list(asteroids) -- detected) |> MapSet.new(), station, Enum.reverse(detected) ++ destroyed)
    end
  end

  def detected_from_point_in_order(asteroids, {x0, y0} = point) do
    asteroids
    |> Enum.filter(&(&1 != point))
    |> Enum.map(fn asteroid ->
      {asteroid, is_way_blocked(asteroids, point, asteroid)}
    end)
    |> Enum.filter(fn {_, blocked} -> blocked == false end)
    |> Enum.map(& elem(&1, 0))
    |> Enum.map(fn {x, y} = asteroid ->
      deg = rad2deg(:math.atan2(y0 - y, x0 - x)) - 90

      deg = case deg < 0 do
        true -> deg + 360.0
        false -> deg
      end

      {asteroid, deg}
    end)
    |> Enum.sort_by(fn {_, rad} -> rad end)
    |> Enum.map(& elem(&1, 0))
  end

  def rad2deg(x) do
    x * (180/:math.pi)
  end

  def is_way_blocked(asteroids, {x1, y1} = a1, {x2, y2} = a2) do
    x_range = x1..x2
    y_range = y1..y2

    asteroids_between =
      for x <- x_range, y <- y_range do
        {x, y}
      end
      |> Enum.filter(&MapSet.member?(asteroids, &1))
      |> Enum.filter(&(&1 != a1 and &1 != a2))

    asteroids_between
    |> Enum.any?(fn coordinates ->
      range_from_line({x1, y1}, {x2, y2}, coordinates) == 0.0
    end)
  end

  def range_from_line({x1, y1}, {x2, y2}, {x0, y0}) do
    numerator = abs((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1)

    denominator = :math.sqrt(:math.pow(y2 - y1, 2) + :math.pow(x2 - x1, 2))

    numerator / denominator
  end
end

Asteroids.solve()
|> IO.inspect()
