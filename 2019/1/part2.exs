defmodule Fuel do
  def calculate(mass) do
    case max(floor((mass / 3)) - 2, 0) do
      0 -> 0
      req_fuel_mass -> req_fuel_mass + calculate(req_fuel_mass)
    end
  end
end


File.read!("./input.txt")
|> String.split("\n")
|> Enum.map(&String.to_integer/1)
|> Enum.map(&Fuel.calculate/1)
|> Enum.sum()
|> IO.inspect()
