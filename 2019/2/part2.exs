


defmodule Machine do
  @mem  File.read!("./input.txt")
  |> String.split(",")
  |> Enum.map(&String.to_integer/1)

  def run_with_args(noun, verb) do
    @mem
    |> List.replace_at(1, noun)
    |> List.replace_at(2, verb)
    |> Machine.execute()
    |> Enum.at(0)
  end

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


for noun <- 0..99, verb <- 0..99 do
  {noun, verb}
end
|> Enum.find(fn {noun, verb} ->
  result = Machine.run_with_args(noun, verb)

  result == 19690720
end)
|> IO.inspect()


