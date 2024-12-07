equations =
  File.read!("data/07.txt")
  |> String.split(["\n", "\r\n"])
  |> Enum.map(fn equation ->
    equation
    |> String.split(": ")
    |> then(fn [test, operands] ->
      {String.to_integer(test), operands |> String.split(" ") |> Enum.map(&String.to_integer/1)}
    end)
  end)

concat = fn a, b -> a * :math.pow(10, 1 + floor(:math.log10(b))) + b end

part1_expansion = fn a, b -> [a + b, a * b] end

part2_expansion = fn a, b ->
  [concat.(a, b) | part1_expansion.(a, b)]
end

has_result = fn {result, operands}, expansion ->
  for operand <- operands, reduce: [] do
    [] ->
      [operand]

    results ->
      results
      |> Enum.flat_map(fn result ->
        expansion.(result, operand)
      end)
      |> Enum.filter(&(&1 <= result))
  end
  |> Enum.any?(&(&1 == result))
end

total_valid = fn expansion ->
  equations
  |> Enum.filter(&has_result.(&1, expansion))
  |> Enum.map(&elem(&1, 0))
  |> Enum.sum()
end

IO.puts("Part 1: #{total_valid.(part1_expansion)}")
IO.puts("Part 2: #{total_valid.(part2_expansion)}")
