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

defmodule Robot do
  def run do
    program =
      File.read!("./input.txt")
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)

    state = IntCode.State.new(program)

    position = {{0, 0}, :up}

    panel_colors = empty_panel_colors() |> set_panel_color({0, 0}, 1)

    paint(state, position, panel_colors)
  end

  def walk({{x, y}, :up}), do: {{x, y + 1}, :up}
  def walk({{x, y}, :down}), do: {{x, y - 1}, :down}
  def walk({{x, y}, :right}), do: {{x + 1, y}, :right}
  def walk({{x, y}, :left}), do: {{x - 1, y}, :left}

  def empty_panel_colors(), do: {%{}, MapSet.new()}
  def get_panel_color({colors, _}, coordinates), do: Map.get(colors, coordinates, 0)

  def render(panel_colors, robot_pos) do
    for y <- 10..-10 do
      for x <- -10..50 do
        case {x, y} do
          ^robot_pos -> 3
          pos -> get_panel_color(panel_colors, pos)
        end
      end
      |> Enum.map(fn
        0 -> "."
        1 -> "#"
        3 -> "o"
      end)
      |> Enum.join()
      |> IO.puts()
    end
  end

  def set_panel_color({colors, painted}, coordinates, color),
    do: {Map.put(colors, coordinates, color), MapSet.put(painted, coordinates)}

  def paint(state, {robot_position, robot_direction}, panel_colors) do
    result =
      state
      |> IntCode.State.set_input(get_panel_color(panel_colors, robot_position))
      |> IntCode.VM.execute_for_outputs(2)

    case result do
      {:halted, _} ->
        render(panel_colors, robot_position)

      {[turn, color_to_paint], state} ->
        panel_colors = set_panel_color(panel_colors, robot_position, color_to_paint)

        new_direction =
          case turn do
            0 -> rotate_left(robot_direction)
            1 -> rotate_right(robot_direction)
          end

        new_robot_position = walk({robot_position, new_direction})

        paint(state |> IntCode.State.truncate_outputs(), new_robot_position, panel_colors)
    end
  end

  @directions [:up, :right, :down, :left]
  def rotate_right(direction) do
    index = Enum.find_index(@directions, &(&1 == direction))

    case index + 1 >= length(@directions) do
      true -> Enum.at(@directions, 0)
      false -> Enum.at(@directions, index + 1)
    end
  end

  def rotate_left(direction) do
    index = Enum.find_index(@directions, &(&1 == direction))

    case index == 0 do
      true -> List.last(@directions)
      false -> Enum.at(@directions, index - 1)
    end
  end
end

Robot.run()
