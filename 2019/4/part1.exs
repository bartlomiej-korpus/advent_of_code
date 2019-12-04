defmodule Passwords do
  @input 172851..675869

  def solve() do
    @input
    |> Enum.filter(fn number ->
      is_six_digit(number) && has_double_digit(number) && never_decreases(number)
    end)
    |> Enum.count()
  end

  def is_six_digit(number) do
    number >= 100000 and number <= 999999
  end

  def has_double_digit(number) do
    Integer.to_string(number)
    |> String.split("")
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.any?(fn [x, y] -> x == y end)
  end

  def never_decreases(number) do
    Integer.to_string(number)
    |> String.split("")
    |> Enum.filter(& &1 !== "")
    |> Enum.map(&String.to_integer/1)
    |> Enum.reduce({0, true}, fn
      _, {_, false} = val -> val
      digit, {last, true} when digit >= last -> {digit, true}
      digit, {last, true} when digit < last -> {digit, false}
    end)
    |> elem(1)
  end
end

Passwords.solve() |> IO.inspect
