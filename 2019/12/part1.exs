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
    @input
    |> create_system()
    |> tick(1000)
    |> system_total_energy()
  end

  def tick(system, max_steps, step \\ 0) do
    if step >= max_steps do
      system
    else
      system
      |> apply_gravity()
      |> apply_velocity()
      |> tick(max_steps, step+1)
    end
  end

  def system_total_energy(system) do
    system
    |> Enum.map(fn planet ->
      planet_potential_energy(planet) * planet_kinetic_energy(planet)
    end)
    |> Enum.sum()
  end

  def planet_potential_energy(planet) do
    Tuple.to_list(planet.position)
    |> Enum.map(&Kernel.abs/1)
    |> Enum.sum()
  end

  def planet_kinetic_energy(planet) do
    Tuple.to_list(planet.velocity)
    |> Enum.map(&Kernel.abs/1)
    |> Enum.sum()
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
