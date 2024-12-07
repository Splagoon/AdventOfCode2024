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

part1_expansion = fn a, b -> [a + b, a * b] end

part2_expansion = fn a, b ->
  [String.to_integer(to_string(a) <> to_string(b)) | part1_expansion.(a, b)]
end

get_all_results = fn operands, expansion ->
  for operand <- operands, reduce: [] do
    [] ->
      [operand]

    results ->
      results
      |> Enum.flat_map(fn result ->
        expansion.(result, operand)
      end)
  end
end

total_valid = fn expansion ->
  equations
  |> Enum.filter(fn {result, operands} ->
    result in get_all_results.(operands, expansion)
  end)
  |> Enum.map(&elem(&1, 0))
  |> Enum.sum()
end

IO.puts("Part 1: #{total_valid.(part1_expansion)}")
IO.puts("Part 2: #{total_valid.(part2_expansion)}")
