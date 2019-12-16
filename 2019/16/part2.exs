defmodule FFT do
  @input File.read!("./input.txt")
         |> String.split("")
         |> Enum.filter(&(&1 != ""))
         |> Enum.map(&String.to_integer/1)
         |> List.duplicate(10000)
         |> Enum.flat_map(& &1)
         |> Enum.drop(5_975_677)

  def run() do
    @input
    |> run_phase()
    |> Enum.take(8)
    |> Enum.join()
  end

  def run_phase(input, phase \\ 0)

  def run_phase(input, 100), do: input

  def run_phase(input, phase) do
    input
    |> Enum.reverse()
    |> Enum.reduce([], fn
      el, [] ->
        [el]

      el, [previous | _] = list ->
        [rem(el + previous, 10) | list]
    end)
    |> run_phase(phase + 1)
  end
end

FFT.run()
|> IO.inspect()
