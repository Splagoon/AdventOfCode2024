{list1, list2} =
  File.read!("data/01.txt")
  |> String.split(["\n", "\r\n"])
  |> Enum.map(fn line ->
    line
    |> String.split("   ")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end)
  |> Enum.unzip()

part1 =
  [Enum.sort(list1), Enum.sort(list2)]
  |> Enum.zip()
  |> Enum.map(fn {a, b} ->
    abs(a - b)
  end)
  |> Enum.sum()

list2_freqs = Enum.frequencies(list2)

part2 =
  list1
  |> Enum.map(&(&1 * Map.get(list2_freqs, &1, 0)))
  |> Enum.sum()

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
