
defmodule Machine do
  def execute(mem), do: execute(mem, 0)

  def execute(mem, pc) do
    ins = Enum.slice(mem, pc, 4)
    case ins do
      [99 | _] -> mem
      ins -> exec(mem, ins) |> execute(pc + 4)
    end
  end

  def exec(mem, [1, one, two, dest]) do
    mem |> List.replace_at(dest, Enum.at(mem, one) + Enum.at(mem, two))
  end

  def exec(mem, [2, one, two, dest]) do
    mem |> List.replace_at(dest, Enum.at(mem, one) * Enum.at(mem, two))
  end
end


File.read!("./input.txt")
|> String.split(",")
|> Enum.map(&String.to_integer/1)
|> List.replace_at(1, 12)
|> List.replace_at(2, 2)
|> Machine.execute()
|> IO.inspect
