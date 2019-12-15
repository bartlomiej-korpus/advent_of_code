defmodule IntCode.State do
  defstruct mem: nil, io: nil, rb: 0, pc: 0, input: nil, output: nil

  def new(program) do
    %__MODULE__{
      mem: :array.from_list(program, 0),
      rb: 0,
      pc: 0,
      input: nil,
      output: []
    }
  end

  def set_mem(state, address, value) do
    %{
      state
      | mem: :array.set(address, value, state.mem)
    }
  end

  def get_mem(state, address) do
    :array.get(address, state.mem)
  end

  def set_pc(state, value) do
    %{
      state
      | pc: value
    }
  end

  def set_rb(state, value) do
    %{
      state
      | rb: value
    }
  end

  def set_input(state, input) do
    %{
      state
      | input: input
    }
  end

  def add_output(state, value) do
    %{
      state
      | output: [value | state.output]
    }
  end

  def truncate_outputs(state) do
    %{
      state
      | output: []
    }
  end
end

defmodule IntCode.VM do
  alias IntCode.State

  @instruction_parameter_counts %{
    99 => 0,
    1 => 3,
    2 => 3,
    3 => 1,
    4 => 1,
    5 => 2,
    6 => 2,
    7 => 3,
    8 => 3,
    9 => 1
  }

  def execute_for_outputs(state, outputs_num) do
    decoded_instruction = decode(state)
    {opcode, _, _, _} = decoded_instruction

    case opcode do
      99 ->
        {:halted, state}

      _ ->
        case do_instruction(state, decoded_instruction) do
          %State{output: output} = new_state when length(output) == outputs_num ->
            {output, new_state}

          new_state ->
            execute_for_outputs(new_state, outputs_num)
        end
    end
  end

  def execute(state) do
    decoded_instruction = decode(state)
    {opcode, _, _, _} = decoded_instruction

    case opcode do
      99 -> state
      _ -> do_instruction(state, decoded_instruction) |> execute()
    end
  end

  def decode(state) do
    val = State.get_mem(state, state.pc)

    opcode = decode_opcode(val)
    parameter_modes = decode_parameter_modes(val)

    parameters_count = Map.fetch!(@instruction_parameter_counts, opcode)

    parameters =
      (state.pc + 1)..(state.pc + parameters_count)
      |> Enum.map(fn addr -> State.get_mem(state, addr) end)

    size = 1 + parameters_count

    {opcode, parameter_modes, parameters, size}
  end

  def decode_opcode(num) do
    rem(num, 100)
  end

  def decode_parameter_modes(num) do
    Integer.digits(num)
    |> Enum.reverse()
    |> Enum.drop(2)
  end

  defmacro fetch(addr) do
    quote do
      IntCode.State.get_mem(var!(state), unquote(addr))
    end
  end

  def do_instruction(state, {3, parameter_modes, params, size}) do
    [dest] = fetch_params_addresses(state, parameter_modes, params)

    input_value = state.input

    state
    |> State.set_mem(dest, input_value)
    |> State.set_pc(state.pc + size)
  end

  def do_instruction(state, {4, parameter_modes, params, size}) do
    [val] = fetch_params_addresses(state, parameter_modes, params)

    state
    |> State.set_pc(state.pc + size)
    |> State.add_output(fetch(val))
  end

  def do_instruction(state, {1, parameter_modes, params, size}) do
    [one, two, dest] = fetch_params_addresses(state, parameter_modes, params)

    state
    |> State.set_mem(dest, fetch(one) + fetch(two))
    |> State.set_pc(state.pc + size)
  end

  def do_instruction(state, {2, parameter_modes, params, size}) do
    [one, two, dest] = fetch_params_addresses(state, parameter_modes, params)

    state
    |> State.set_mem(dest, fetch(one) * fetch(two))
    |> State.set_pc(state.pc + size)
  end

  def do_instruction(state, {5, parameter_modes, params, size}) do
    [one, two] = fetch_params_addresses(state, parameter_modes, params)

    state
    |> State.set_pc(
      case fetch(one) != 0 do
        true -> fetch(two)
        false -> state.pc + size
      end
    )
  end

  def do_instruction(state, {6, parameter_modes, params, size}) do
    [one, two] = fetch_params_addresses(state, parameter_modes, params)

    state
    |> State.set_pc(
      case fetch(one) == 0 do
        true -> fetch(two)
        false -> state.pc + size
      end
    )
  end

  def do_instruction(state, {7, parameter_modes, params, size}) do
    [one, two, dest] = fetch_params_addresses(state, parameter_modes, params)

    state
    |> State.set_mem(
      dest,
      case fetch(one) < fetch(two) do
        true -> 1
        false -> 0
      end
    )
    |> State.set_pc(state.pc + size)
  end

  def do_instruction(state, {8, parameter_modes, params, size}) do
    [one, two, dest] = fetch_params_addresses(state, parameter_modes, params)

    state
    |> State.set_mem(
      dest,
      case fetch(one) == fetch(two) do
        true -> 1
        false -> 0
      end
    )
    |> State.set_pc(state.pc + size)
  end

  def do_instruction(state, {9, parameter_modes, params, size}) do
    [val] = fetch_params_addresses(state, parameter_modes, params)

    state
    |> State.set_rb(state.rb + fetch(val))
    |> State.set_pc(state.pc + size)
  end

  def fetch_params_addresses(state, modes, params) do
    Enum.with_index(params)
    |> Enum.map(fn {param, index} ->
      mode = Enum.at(modes, index, 0)

      case mode do
        0 -> param
        1 -> state.pc + index + 1
        2 -> state.rb + param
      end
    end)
  end
end

defmodule RemoteControl do
  @input File.read!("./input.txt")
  |> String.split(",")
  |> Enum.map(&String.to_integer/1)

  @directions  [north: 1, south: 2, east: 4, west: 3]

  def run do
    state = IntCode.State.new(@input)

    droid_location = {0, 0}

    map = %{{0, 0} => 1}

    tick_game(state, droid_location, map)
  end

  def tick_game(state, droid_location, map, step \\ 1) do
    @directions
    |> Enum.map(fn {direction, code} ->
      {new_coordinates, _} = walk({droid_location, direction})
      {direction, code, new_coordinates}
    end)
    |> Enum.filter(fn {_, _, new_coordinates} ->
      not Map.has_key?(map, new_coordinates)
    end)
    |> Enum.map(fn {_, code, new_coordinates} ->

      {[result], state} = state
      |> IntCode.State.truncate_outputs()
      |> IntCode.State.set_input(code)
      |> IntCode.VM.execute_for_outputs(1)

      map = Map.put(map, new_coordinates, result)

      if result == 2 do
        IO.puts("oxygen at step: #{step}")
      end

      {new_coordinates, result, state, map}
    end)
    |> Enum.filter(fn {_, result, _, _} -> result != 0 end)
    |> Enum.map(fn {new_coordinates, _, state, map} ->
      tick_game(state, new_coordinates, map, step + 1)
    end)
    |> Enum.reduce(%{}, &Map.merge/2)
  end

  def walk({{x, y}, :north}), do: {{x, y + 1}, :north}
  def walk({{x, y}, :south}), do: {{x, y - 1}, :south}
  def walk({{x, y}, :east}), do: {{x + 1, y}, :east}
  def walk({{x, y}, :west}), do: {{x - 1, y}, :west}
end

RemoteControl.run()
|> IO.inspect()
