defmodule FFT do
  @input File.read!("./input.txt")
         |> String.split("")
         |> Enum.filter(&(&1 != ""))
         |> Enum.map(&String.to_integer/1)

  @base_pattern [0, 1, 0, -1]

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
    |> Enum.with_index(1)
    |> Enum.map(fn {element, index} ->
      pattern =
        Enum.flat_map(@base_pattern, fn pattern_digit ->
          Stream.cycle([pattern_digit]) |> Enum.take(index)
        end)
        |> Stream.cycle()
        |> Stream.drop(1)

        Enum.zip(input, pattern)
        |> Enum.map(fn {one, two} ->
          one * two
        end)
        |> Enum.sum()
        |> rem(10)
        |> abs()
    end)
    |> run_phase(phase + 1)
  end
end

FFT.run()
|> IO.inspect()
