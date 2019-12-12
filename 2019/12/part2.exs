defmodule Moons do
  @input File.read!("./input.txt")
         |> String.split("\n")
         |> Enum.map(fn line ->
           Regex.run(~r/<x=(.+), y=(.+), z=(.+)>/, line)
         end)
         |> Enum.map(fn [_ | tl] -> tl end)
         |> Enum.map(fn coordinates ->
           Enum.map(coordinates, &String.to_integer/1)
         end)
         |> Enum.map(fn [x, y, z] -> {x, y, z} end)

  def solve() do
    system = @input
    |> create_system()

    fetch_position_at_index = fn index ->
      fn planet ->
        elem(planet.position, index)
      end
    end

    x_period = find_cycle(system, fetch_position_at_index.(0))
    y_period = find_cycle(system, fetch_position_at_index.(1))
    z_period = find_cycle(system, fetch_position_at_index.(2))

    x_period
    |> lcm(y_period)
    |> lcm(z_period)
  end

  def lcm(a, b), do: ((abs(a * b))/gcd(a,b)) |> trunc()

  def gcd(a, 0), do: a
  def gcd(a, b), do: gcd(b, rem(a, b))

  def find_cycle(system, extractor_fun) do
    starting_positions = Enum.map(system, extractor_fun)

    tick(system, 0, fn system_after ->
      Enum.map(system_after, extractor_fun) == starting_positions
    end)
  end

  def tick(system, step \\ 0, termination_condition) do
    if step > 0 and termination_condition.(system) do
      step + 1
    else
      system
      |> apply_gravity()
      |> apply_velocity()
      |> tick(step + 1, termination_condition)
    end
  end

  def apply_gravity(system) do
    system
    |> Enum.map(fn planet ->
      system
      |> Enum.filter(&(&1 !== planet))
      |> Enum.reduce(planet, fn planet2, planet1 ->
        apply_gravity_between(planet1, planet2)
      end)
    end)
  end

  def apply_velocity(system) do
    Enum.map(system, &apply_planet_velocity/1)
  end

  def apply_planet_velocity(planet) do
    %{
      planet
      | position:
          Enum.zip(Tuple.to_list(planet.velocity), Tuple.to_list(planet.position))
          |> Enum.map(fn {vel, pos} -> vel + pos end)
          |> List.to_tuple()
    }
  end

  def apply_gravity_between(planet1, planet2) do
    dvelocity =
      Enum.zip(Tuple.to_list(planet1.position), Tuple.to_list(planet2.position))
      |> Enum.map(fn {c1, c2} ->
        cond do
          c1 > c2 -> -1
          c1 < c2 -> 1
          c1 == c2 -> 0
        end
      end)

    new_velocity =
      planet1.velocity
      |> Tuple.to_list()
      |> Enum.zip(dvelocity)
      |> Enum.map(fn {vel, dvel} -> vel + dvel end)
      |> List.to_tuple()

    %{
      planet1
      | velocity: new_velocity
    }
  end

  def create_system(moons_positions) do
    moons_positions
    |> Enum.with_index()
    |> Enum.map(fn {moon_position, index} ->
      %{
        index: index,
        position: moon_position,
        velocity: {0, 0, 0}
      }
    end)
  end
end

Moons.solve()
|> IO.inspect()
