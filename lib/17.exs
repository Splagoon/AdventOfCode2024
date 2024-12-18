{registers, program} =
  File.read!("data/17.txt")
  |> String.split(["\n\n", "\r\n\r\n"])
  |> then(fn [registers_str, program_str] ->
    [a, b, c] =
      registers_str
      |> String.split(["\n", "\r\n"])
      |> Enum.map(fn str ->
        str
        |> String.split(": ")
        |> Enum.at(1)
        |> String.to_integer()
      end)

    program =
      program_str
      |> String.split(": ")
      |> Enum.at(1)
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)

    {%{a: a, b: b, c: c}, program}
  end)

defmodule Day17 do
  defp combo(registers, operand) do
    case operand do
      x when x in 0..3 -> x
      4 -> registers.a
      5 -> registers.b
      6 -> registers.c
      7 -> :err
    end
  end

  defp divide(registers, operand, result_register) do
    operand = combo(registers, operand)
    %{registers | result_register => div(registers.a, 2 ** operand)}
  end

  defp run_opcode(registers, opcode, operand, allow_jump \\ true) do
    case opcode do
      0 ->
        # adv
        {nil, divide(registers, operand, :a), nil}

      1 ->
        # bxl
        {nil, %{registers | b: Bitwise.bxor(registers.b, operand)}, nil}

      2 ->
        # bst
        operand = combo(registers, operand)
        {nil, %{registers | b: rem(operand, 8)}, nil}

      3 ->
        # jnz
        new_ip = if registers.a == 0 or not allow_jump, do: nil, else: operand
        {new_ip, registers, nil}

      4 ->
        # bxc
        {nil, %{registers | b: Bitwise.bxor(registers.b, registers.c)}, nil}

      5 ->
        # out
        operand = combo(registers, operand)
        {nil, registers, rem(operand, 8)}

      6 ->
        # bdv
        {nil, divide(registers, operand, :b), nil}

      7 ->
        # cdv
        {nil, divide(registers, operand, :c), nil}
    end
  end

  defp run(program, registers, ip, out, allow_jump) do
    case {Enum.at(program, ip, :halt), Enum.at(program, ip + 1, :halt)} do
      {:halt, _} ->
        out

      {_, :halt} ->
        out

      {opcode, operand} ->
        {new_ip, new_registers, output} = run_opcode(registers, opcode, operand, allow_jump)

        run(
          program,
          new_registers,
          if(is_nil(new_ip), do: ip + 2, else: new_ip),
          if(is_nil(output), do: out, else: [output | out]),
          allow_jump
        )
    end
  end

  def run_program(program, registers, allow_jump \\ true),
    do: run(program, registers, 0, [], allow_jump) |> Enum.reverse()

  defp run_quine(program, registers, ip, src) do
    case {Enum.at(program, ip, :halt), Enum.at(program, ip + 1, :halt)} do
      {:halt, _} ->
        Enum.empty?(src)

      {_, :halt} ->
        Enum.empty?(src)

      {opcode, operand} ->
        {new_ip, new_registers, output} = run_opcode(registers, opcode, operand)

        {continue, new_src} =
          if not is_nil(output) do
            case src do
              [] -> {false, nil}
              [head | tail] -> {head == output, tail}
            end
          else
            {true, src}
          end

        if continue do
          run_quine(
            program,
            new_registers,
            if(is_nil(new_ip), do: ip + 2, else: new_ip),
            new_src
          )
        else
          false
        end
    end
  end

  def seek_quine(program, registers),
    do: run_quine(program, registers, 0, program)
end

part1 =
  Day17.run_program(program, registers)
  |> Enum.join(",")

part2_possible_solutions =
  for d <- Enum.reverse(program), reduce: [0] do
    found ->
      new_found =
        found
        |> Enum.flat_map(fn f ->
          possible =
            0..7
            |> Enum.map(fn n -> Bitwise.<<<(f, 3) + n end)

          filtered =
            possible
            |> Enum.filter(fn a ->
              Day17.run_program(program, %{registers | a: a}, false)
              |> then(fn [out] -> out == d end)
            end)

          if Enum.empty?(filtered), do: possible, else: filtered
        end)

      new_found
  end

part2 =
  part2_possible_solutions
  |> Enum.find(fn a ->
    Day17.seek_quine(program, %{registers | a: a})
  end)

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
