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

  def solve() do
    @input
    |> Enum.map(fn candidate_asteroid ->
      results =
        @input
        |> Enum.filter(&(&1 != candidate_asteroid))
        |> Enum.map(fn asteroid ->
          is_way_blocked(@input, candidate_asteroid, asteroid)
        end)
        |> Enum.count(&(&1 == false))

      {candidate_asteroid, results}
    end)
    |> Enum.max_by(fn {_, num} -> num end)
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
    # IO.inspect("candidate #{x1} #{y1} to #{x2} #{y2} checking if blocked by #{x0} #{y0}")
    numerator = abs((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1)

    denominator = :math.sqrt(:math.pow(y2 - y1, 2) + :math.pow(x2 - x1, 2))

    numerator / denominator
  end
end

Asteroids.solve()
|> IO.inspect()
