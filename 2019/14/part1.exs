defmodule Leftovers do
  def empty(), do: %{}

  def add(leftovers, {symbol, amount}) do
    current = Map.get(leftovers, symbol, 0)

    Map.put(leftovers, symbol, current + amount)
  end

  def take(leftovers, {symbol, amount}) do
    current = Map.get(leftovers, symbol, 0)

    to_take = min(current, amount)

    leftovers = Map.put(leftovers, symbol, current - to_take)

    new_amount = amount - to_take

    if new_amount == 0 do
      {nil, leftovers}
    else
      {{symbol, new_amount}, leftovers}
    end
  end
end

defmodule Nanofactory do
  @recipes File.read!("./input.txt")
           |> String.split("\n")
           |> Enum.map(fn str -> Regex.scan(~r/(\d+) (\w+)/, str) end)
           |> Enum.map(fn scanned ->
             Enum.map(scanned, &tl/1)
           end)
           |> Enum.map(fn ingredients ->
             Enum.map(ingredients, fn [amount, type] ->
               {type, String.to_integer(amount)}
             end)
           end)
           |> Enum.map(fn ingredients ->
             %{
               requirements: Enum.take(ingredients, length(ingredients) - 1),
               result: List.last(ingredients)
             }
           end)

  def run() do
    state = start()

    state
    |> tick()

  end

  def tick(%{demanded: %{"ORE" => x} = demanded}) when map_size(demanded) == 1 do
    x
  end

  def tick(state) do
    [search_for | _] = state.demanded |> Enum.to_list() |> Enum.filter(fn {s, _} -> s != "ORE" end)

    others = Map.delete(state.demanded, elem(search_for, 0))

    {symbol, amount} = search_for
    recipe = Enum.find(@recipes, &(elem(&1.result, 0) == symbol))

    {requirements, leftover} = calculate_reaction(recipe, amount)

    {requirements, leftovers} = Leftovers.add(state.leftovers, leftover)
    |> reduce_with_leftovers(requirements)


    new_demanded = Enum.reduce(requirements, others, fn {symbol, amount}, demanded ->
      current = Map.get(demanded, symbol, 0)

      Map.put(demanded, symbol, current + amount)
    end)

    %{
      demanded: new_demanded,
      leftovers: leftovers
    } |> tick()

  end


  def reduce_with_leftovers(leftovers, requirements) do
    Enum.reduce(requirements, {[], leftovers}, fn component, {r, leftovers} ->
      case Leftovers.take(leftovers, component) do
        {nil, leftovers} -> {r, leftovers}
        {component, leftovers} -> {[component | r], leftovers}
      end
    end)
  end

  def calculate_reaction(recipe, for_amount) do
    times =
      trunc(
        div(for_amount, elem(recipe.result, 1)) +
          if rem(for_amount, elem(recipe.result, 1)) > 0 do
            1
          else
            0
          end
      )


    requirements =
      Enum.map(recipe.requirements, fn {symbol, amount} ->
        {symbol, amount * times}
      end)

    left_results = elem(recipe.result, 1) * times - for_amount

    {symbol, _} = recipe.result

    leftover = {symbol, left_results}

    {requirements, leftover}
  end

  def start() do
    %{
      demanded: %{
        "FUEL" => 1
      },
      leftovers: Leftovers.empty()
    }
  end
end

Nanofactory.run()
|> IO.inspect()
