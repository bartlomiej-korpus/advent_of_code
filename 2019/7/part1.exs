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

defmodule IntCode do
  @mem File.read!("./input.txt")
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

  def execute(io_pid) when is_pid(io_pid), do: execute({@mem, 0, io_pid})

  def execute({mem, pc, io_pid}) do
    decoded_instruction = decode(Enum.drop(mem, pc))
    {opcode, _, _, _} = decoded_instruction

    case opcode do
      99 -> mem
      _ -> do_instruction({mem, pc, io_pid}, decoded_instruction) |> execute()
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

  def do_instruction({mem, pc, io_pid}, {3, _, [dest], size}) do
    input_value = IntCodeIO.get_next(io_pid)

    mem = List.replace_at(mem, dest, input_value)

    {mem, pc + size, io_pid}
  end

  def do_instruction({mem, pc, io_pid}, {4, modes, [one], size}) do
    value = fetch(mem, get_parameter_mode(modes, 0), one)
    IntCodeIO.output_next(io_pid, value)

    {mem, pc + size, io_pid}
  end

  def do_instruction({mem, pc, io_pid}, {1, parameter_modes, [one, two, dest], size}) do
    one = fetch(mem, get_parameter_mode(parameter_modes, 0), one)
    two = fetch(mem, get_parameter_mode(parameter_modes, 1), two)
    mem = List.replace_at(mem, dest, one + two)

    {mem, pc + size, io_pid}
  end

  def do_instruction({mem, pc, io_pid}, {2, parameter_modes, [one, two, dest], size}) do
    one = fetch(mem, get_parameter_mode(parameter_modes, 0), one)
    two = fetch(mem, get_parameter_mode(parameter_modes, 1), two)
    mem = List.replace_at(mem, dest, one * two)

    {mem, pc + size, io_pid}
  end

  def do_instruction({mem, pc, io_pid}, {5, parameter_modes, [one, two], size}) do
    one = fetch(mem, get_parameter_mode(parameter_modes, 0), one)
    two = fetch(mem, get_parameter_mode(parameter_modes, 1), two)

    if one != 0 do
      {mem, two, io_pid}
    else
      {mem, pc + size, io_pid}
    end
  end

  def do_instruction({mem, pc, io_pid}, {6, parameter_modes, [one, two], size}) do
    one = fetch(mem, get_parameter_mode(parameter_modes, 0), one)
    two = fetch(mem, get_parameter_mode(parameter_modes, 1), two)

    if one == 0 do
      {mem, two, io_pid}
    else
      {mem, pc + size, io_pid}
    end
  end

  def do_instruction({mem, pc, io_pid}, {7, parameter_modes, [one, two, dest], size}) do
    one = fetch(mem, get_parameter_mode(parameter_modes, 0), one)
    two = fetch(mem, get_parameter_mode(parameter_modes, 1), two)

    if one < two do
      {List.replace_at(mem, dest, 1), pc + size, io_pid}
    else
      {List.replace_at(mem, dest, 0), pc + size, io_pid}
    end
  end

  def do_instruction({mem, pc, io_pid}, {8, parameter_modes, [one, two, dest], size}) do
    one = fetch(mem, get_parameter_mode(parameter_modes, 0), one)
    two = fetch(mem, get_parameter_mode(parameter_modes, 1), two)

    if one == two do
      {List.replace_at(mem, dest, 1), pc + size, io_pid}
    else
      {List.replace_at(mem, dest, 0), pc + size, io_pid}
    end
  end

  def fetch(_, 1, param), do: param
  def fetch(mem, 0, param), do: Enum.at(mem, param)

  def get_parameter_mode(modes, param_num) do
    Enum.at(modes, param_num, 0)
  end
end

defmodule AmplificationCircuit do
  def create(seq) do
    amp_a_io = IntCodeIO.start_link()
    IntCodeIO.add_next(amp_a_io, Enum.at(seq, 0))

    amp_b_io = IntCodeIO.start_link()
    IntCodeIO.add_next(amp_b_io, Enum.at(seq, 1))

    amp_c_io = IntCodeIO.start_link()
    IntCodeIO.add_next(amp_c_io, Enum.at(seq, 2))

    amp_d_io = IntCodeIO.start_link()
    IntCodeIO.add_next(amp_d_io, Enum.at(seq, 3))

    amp_e_io = IntCodeIO.start_link()
    IntCodeIO.add_next(amp_e_io, Enum.at(seq, 4))

    IntCodeIO.set_on_output(amp_a_io, fn output ->
      IntCodeIO.add_next(amp_b_io, output)
    end)

    IntCodeIO.set_on_output(amp_b_io, fn output ->
      IntCodeIO.add_next(amp_c_io, output)
    end)

    IntCodeIO.set_on_output(amp_c_io, fn output ->
      IntCodeIO.add_next(amp_d_io, output)
    end)

    IntCodeIO.set_on_output(amp_d_io, fn output ->
      IntCodeIO.add_next(amp_e_io, output)
    end)

    thruster_io = IntCodeIO.start_link()

    IntCodeIO.set_on_output(amp_e_io, fn output ->
      IntCodeIO.add_next(thruster_io, output)
    end)

    [amp_a_io, amp_b_io, amp_c_io, amp_d_io, amp_e_io]
    |> Enum.map(fn io ->
      spawn_link(fn ->
        IntCode.execute(io)
      end)
    end)

    IntCodeIO.add_next(amp_a_io, 0)

    [thruster_io, amp_a_io, amp_b_io, amp_c_io, amp_d_io, amp_e_io]
  end
end

# https://elixirforum.com/t/most-elegant-way-to-generate-all-permutations/2706/2?u=bartlomiej
defmodule Permutations do
  def generate([]), do: [[]]
  def generate(list), do: for(elem <- list, rest <- generate(list -- [elem]), do: [elem | rest])
end

Permutations.generate([0, 1, 2, 3, 4])
|> Enum.map(fn seq ->
  seq_str = seq |> Enum.join()

  processes = AmplificationCircuit.create(seq)

  [thruster_io | _] = processes

  val = IntCodeIO.get_next(thruster_io)

  Enum.map(processes, fn pid ->
    GenServer.stop(pid)
  end)

  {seq_str, val}
end)
|> Enum.max_by(fn {_, val} -> val end)
|> IO.inspect()
