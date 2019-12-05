
defmodule IntCodeIO do
  use Agent

  def start_link() do
    Agent.start_link(fn -> [5] end, name: __MODULE__)
  end

  def get_next() do
    next = Agent.get(__MODULE__, & hd(&1))

    Agent.update(__MODULE__, & tl(&1))

    next
  end

  def output_next(val) do
    IO.puts(val)
  end
end

defmodule IntCode do
  @mem  File.read!("./input.txt")
  |> String.split(",")
  |> Enum.map(&String.to_integer/1)

  @instruction_parameter_counts %{
    99 => 0,
    1 => 3,
    2 => 3,
    3 => 1,
    4 => 1,
    5 => 2,
    6 => 2,
    7 => 3,
    8 => 3
  }

  def execute(), do: execute({@mem, 0})

  def execute({mem, pc}) do
    decoded_instruction = decode(Enum.drop(mem, pc))
    {opcode, _, _, _} = decoded_instruction

    case opcode do
      99 -> mem
      _ -> do_instruction({mem, pc}, decoded_instruction) |> execute()
    end
  end

  def decode(mem) do
    opcode = decode_opcode(hd(mem))
    parameter_modes = decode_parameter_modes(hd(mem))
    parameters_count = Map.fetch!(@instruction_parameter_counts, opcode)
    parameters = Enum.slice(mem, 1, parameters_count)
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

  def do_instruction({mem, pc},  {3, _, [dest], size}) do
    input_value = IntCodeIO.get_next()

    mem = List.replace_at(mem, dest, input_value)

    {mem, pc + size}
  end

  def do_instruction({mem, pc},  {4, modes, [one], size}) do
    value = fetch(mem, get_parameter_mode(modes, 0), one)
    IntCodeIO.output_next(value)

    {mem, pc + size}
  end

  def do_instruction({mem, pc}, {1, parameter_modes, [one, two, dest], size}) do
    one = fetch(mem, get_parameter_mode(parameter_modes, 0), one)
    two = fetch(mem, get_parameter_mode(parameter_modes, 1), two)
    mem =  List.replace_at(mem, dest, one + two)

    {mem, pc + size}
  end

  def do_instruction({mem, pc}, {2, parameter_modes, [one, two, dest], size}) do
    one = fetch(mem, get_parameter_mode(parameter_modes, 0), one)
    two = fetch(mem, get_parameter_mode(parameter_modes, 1), two)
    mem = List.replace_at(mem, dest, one * two)

    {mem, pc + size}
  end

  def do_instruction({mem, pc}, {5, parameter_modes, [one, two], size}) do
    one = fetch(mem, get_parameter_mode(parameter_modes, 0), one)
    two = fetch(mem, get_parameter_mode(parameter_modes, 1), two)

    if one != 0 do
      {mem, two}
    else
      {mem, pc + size}
    end
  end

  def do_instruction({mem, pc}, {6, parameter_modes, [one, two], size}) do
    one = fetch(mem, get_parameter_mode(parameter_modes, 0), one)
    two = fetch(mem, get_parameter_mode(parameter_modes, 1), two)

    if one == 0 do
      {mem, two}
    else
      {mem, pc + size}
    end
  end

  def do_instruction({mem, pc}, {7, parameter_modes, [one, two, dest], size}) do
    one = fetch(mem, get_parameter_mode(parameter_modes, 0), one)
    two = fetch(mem, get_parameter_mode(parameter_modes, 1), two)


    if one < two do
      {List.replace_at(mem, dest, 1), pc + size}
    else
      {List.replace_at(mem, dest, 0), pc + size}
    end
  end

  def do_instruction({mem, pc}, {8, parameter_modes, [one, two, dest], size}) do
    one = fetch(mem, get_parameter_mode(parameter_modes, 0), one)
    two = fetch(mem, get_parameter_mode(parameter_modes, 1), two)


    if one == two do
      {List.replace_at(mem, dest, 1), pc + size}
    else
      {List.replace_at(mem, dest, 0), pc + size}
    end
  end


  def fetch(_, 1, param), do: param
  def fetch(mem, 0, param), do: Enum.at(mem, param)

  def get_parameter_mode(modes, param_num) do
    Enum.at(modes, param_num, 0)
  end
end

IntCodeIO.start_link()

IntCode.execute()

