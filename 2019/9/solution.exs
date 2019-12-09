defmodule IntCodeIO do
  use GenServer

  def get_next(pid) do
    GenServer.call(pid, :get_next, 60000)
  end

  def add_next(pid, val) do
    GenServer.cast(pid, {:add_next, val})
  end

  def set_on_output(pid, fun) do
    GenServer.cast(pid, {:set_on_output, fun})
  end

  def output_next(pid, val) do
    GenServer.cast(pid, {:output_next, val})
  end

  def start_link() do
    {:ok, pid} = GenServer.start_link(IntCodeIO, [])

    pid
  end

  def init(_) do
    {:ok, {[], nil}}
  end

  def handle_call(:get_next, _, {[val | tail], fun}), do: {:reply, val, {tail, fun}}

  def handle_call(:get_next, _, {[], fun}) do
    receive do
      {:"$gen_cast", {:add_next, val}} -> {:reply, val, {[], fun}}
    end
  end

  def handle_cast({:add_next, val}, {data, fun}) do
    {:noreply, {data ++ [val], fun}}
  end

  def handle_cast({:set_on_output, fun}, {data, _}) do
    {:noreply, {data, fun}}
  end

  def handle_cast({:output_next, val}, {_, fun} = state) do
    fun.(val)

    {:noreply, state}
  end
end

defmodule IntCode.State do
  defstruct mem: nil, io: nil, rb: 0, pc: 0

  def new(program, io) do
    %__MODULE__{
      mem: :array.from_list(program, 0),
      io: io,
      rb: 0,
      pc: 0
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

  def execute(state) do
    decoded_instruction = decode(state)
    {opcode, _, _, _} = decoded_instruction

    # IO.inspect(state.mem)
    # # IO.inspect(decoded_instruction)

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

    input_value = IntCodeIO.get_next(state.io)

    state
    |> State.set_mem(dest, input_value)
    |> State.set_pc(state.pc + size)
  end

  def do_instruction(state, {4, parameter_modes, params, size}) do
    [val] = fetch_params_addresses(state, parameter_modes, params)

    IntCodeIO.output_next(state.io, fetch(val))

    state
    |> State.set_pc(state.pc + size)
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

program =
  File.read!("./input.txt")
  |> String.split(",")
  |> Enum.map(&String.to_integer/1)

io = IntCodeIO.start_link()

IntCodeIO.set_on_output(io, fn output ->
  IO.puts(output)
end)

IntCodeIO.add_next(io, 2)

state = IntCode.State.new(program, io)

IntCode.VM.execute(state)

Process.sleep(1000)
