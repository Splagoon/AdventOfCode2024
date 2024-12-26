parse_wires = fn wires ->
  wires
  |> String.split(["\n", "\r\n"])
  |> Enum.map(fn wire ->
    [wire_name, wire_value] = String.split(wire, ": ")
    {wire_name, String.to_integer(wire_value)}
  end)
  |> Enum.into(%{})
end

parse_gates = fn gates ->
  gates
  |> String.split(["\n", "\r\n"])
  |> Enum.map(fn gate ->
    [expression, output] = String.split(gate, " -> ")
    [left, operator, right] = String.split(expression, " ")
    {output, {left, operator, right}}
  end)
  |> Enum.into(%{})
end

{wires, gates} =
  File.read!("data/24.txt")
  |> String.split(["\n\n", "\r\n\r\n"])
  |> then(fn [wires, gates] ->
    {parse_wires.(wires), parse_gates.(gates)}
  end)

z_wires =
  gates
  |> Map.keys()
  |> Enum.filter(&String.starts_with?(&1, "z"))

run_gates = fn gates, wires ->
  f = fn f, wires, i ->
    new_wires =
      for {output, {left, operator, right}} <- Map.to_list(gates), reduce: wires do
        wires ->
          cond do
            Map.has_key?(wires, output) ->
              wires

            Map.has_key?(wires, left) and Map.has_key?(wires, right) ->
              left_val = Map.get(wires, left)
              right_val = Map.get(wires, right)

              out_val =
                case operator do
                  "AND" -> if left_val > 0 and right_val > 0, do: 1, else: 0
                  "OR" -> if left_val > 0 or right_val > 0, do: 1, else: 0
                  "XOR" -> if left_val != right_val, do: 1, else: 0
                end

              Map.put(wires, output, out_val)

            true ->
              wires
          end
      end

    cond do
      Enum.all?(z_wires, &Map.has_key?(new_wires, &1)) ->
        new_wires

      i < 100 ->
        f.(f, new_wires, i + 1)

      true ->
        nil
    end
  end

  f.(f, wires, 0)
end

build_number = fn results, wires ->
  wires
  |> Enum.map(fn wire ->
    wire_num = wire |> String.slice(1..2) |> String.to_integer()
    Map.get(results, wire) * 2 ** wire_num
  end)
  |> Enum.sum()
end

find_half_gate = fn left, op, gates ->
  Enum.find_value(gates, fn {out, gate} ->
    case gate do
      {^left, _, right} when is_nil(op) -> {out, right}
      {right, _, ^left} when is_nil(op) -> {out, right}
      {^left, ^op, right} -> {out, right}
      {right, ^op, ^left} -> {out, right}
      _ -> nil
    end
  end)
  |> then(&if(is_nil(&1), do: {nil, nil}, else: &1))
end

find_gate = fn left, op, right, gates ->
  Enum.find_value(gates, fn {out, gate} ->
    case gate do
      {^left, ^op, ^right} -> out
      {^right, ^op, ^left} -> out
      _ -> nil
    end
  end)
  |> then(&if(is_nil(&1), do: {nil, nil}, else: &1))
end

fix_adder = fn ->
  f = fn f, n, carry_out, gates, swaps ->
    if n > 44 do
      swaps
    else
      n_str = n |> Integer.to_string() |> String.pad_leading(2, "0")
      x_wire = "x#{n_str}"
      y_wire = "y#{n_str}"

      # Half adder

      half_xor_out = find_gate.(x_wire, "XOR", y_wire, gates)

      half_and_out = find_gate.(x_wire, "AND", y_wire, gates)

      # Full adder
      if n == 0 do
        f.(
          f,
          n + 1,
          Map.put(carry_out, n, half_and_out),
          gates,
          swaps
        )
      else
        prev_carry = Map.get(carry_out, n - 1)

        {_full_xor_out, found_carry} = find_half_gate.(half_xor_out, "XOR", gates)
        {_, found_half_xor} = find_half_gate.(prev_carry, "XOR", gates)

        cond do
          prev_carry != found_carry and not is_nil(found_carry) ->
            f.(
              f,
              n,
              %{carry_out | (n - 1) => found_carry},
              %{
                gates
                | found_carry => Map.get(gates, prev_carry),
                  prev_carry => Map.get(gates, found_carry)
              },
              [{found_carry, prev_carry} | swaps]
            )

          half_xor_out != found_half_xor ->
            f.(
              f,
              n,
              carry_out,
              %{
                gates
                | half_xor_out => Map.get(gates, found_half_xor),
                  found_half_xor => Map.get(gates, half_xor_out)
              },
              [{found_half_xor, half_xor_out} | swaps]
            )

          true ->
            {full_and_out, half_xor} = find_half_gate.(prev_carry, "AND", gates)

            if half_xor != half_xor_out do
              f.(
                f,
                n,
                carry_out,
                %{
                  gates
                  | half_xor => Map.get(gates, half_xor_out),
                    half_xor_out => Map.get(gates, half_xor)
                },
                [{half_xor, half_xor_out} | swaps]
              )
            else
              {full_carry_out, half_and} = find_half_gate.(full_and_out, "OR", gates)
              {_, full_and} = find_half_gate.(half_and_out, "OR", gates)

              cond do
                half_and != half_and_out and not is_nil(half_and) ->
                  f.(
                    f,
                    n,
                    carry_out,
                    %{
                      gates
                      | half_and => Map.get(gates, half_and_out),
                        half_and_out => Map.get(gates, half_and)
                    },
                    [{half_and, half_and_out} | swaps]
                  )

                full_and != full_and_out and not is_nil(full_and) ->
                  f.(
                    f,
                    n,
                    carry_out,
                    %{
                      gates
                      | full_and => Map.get(gates, full_and_out),
                        full_and_out => Map.get(gates, full_and)
                    },
                    [{full_and, full_and_out} | swaps]
                  )

                true ->
                  f.(
                    f,
                    n + 1,
                    Map.put(carry_out, n, full_carry_out),
                    gates,
                    swaps
                  )
              end
            end
        end
      end
    end
  end

  f.(f, 0, %{}, gates, [])
end

part1 =
  run_gates.(gates, wires)
  |> build_number.(z_wires)

part2 =
  fix_adder.()
  |> Enum.flat_map(&Tuple.to_list/1)
  |> Enum.sort()
  |> Enum.join(",")

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
