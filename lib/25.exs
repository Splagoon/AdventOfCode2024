{locks, keys} =
  File.read!("data/25.txt")
  |> String.split(["\n\n", "\r\n\r\n"])
  |> Enum.map(fn schematic ->
    schematic
    |> String.split(["\n", "\r\n"])
    |> Enum.with_index()
    |> Enum.flat_map(fn {row, row_index} ->
      row
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.filter(&(elem(&1, 0) == "#"))
      |> Enum.map(fn {_, col_index} -> {col_index, row_index} end)
    end)
    |> MapSet.new()
  end)
  |> Enum.split_with(&MapSet.member?(&1, {0, 0}))

part1 =
  for lock <- locks, key <- keys, reduce: 0 do
    count ->
      if MapSet.disjoint?(lock, key), do: count + 1, else: count
  end

IO.puts("Part 1: #{part1}")
