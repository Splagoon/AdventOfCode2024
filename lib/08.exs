map =
  File.read!("data/08.txt")
  |> String.split(["\n", "\r\n"])
  |> Enum.with_index()
  |> Enum.flat_map(fn {row, row_index} ->
    row
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.map(fn {col, col_index} ->
      {{col_index, row_index},
       case col do
         "." -> nil
         freq -> freq
       end}
    end)
  end)
  |> Enum.into(%{})

distance = fn {ax, ay}, {bx, by} ->
  :math.sqrt(:math.pow(bx - ax, 2) + :math.pow(by - ay, 2))
end

points_in_line = fn {ax, ay}, {bx, by} ->
  filter =
    cond do
      # Vertical line
      ax == bx ->
        fn {x, _} -> x == ax end

      # Horizontal line
      ay == by ->
        fn {_, y} -> y == ay end

      # Sloped line
      true ->
        slope = (by - ay) / (bx - ax)

        fn {x, y} ->
          if x == ax, do: y == ay, else: (y - ay) / (x - ax) == slope
        end
    end

  Map.keys(map) |> Enum.filter(filter)
end

is_antinode_distance = fn pos, a, b ->
  d1 = distance.(pos, a)
  d2 = distance.(pos, b)
  d1 == d2 * 2 or d1 * 2 == d2
end

get_antinodes = fn a, b ->
  for pos <- points_in_line.(a, b), is_antinode_distance.(pos, a, b), do: pos
end

antennae = Map.to_list(map) |> Enum.filter(fn {_, freq} -> freq != nil end)

count_antinodes = fn f ->
  antennae
  |> Enum.flat_map(fn {pos1, freq1} ->
    antennae
    |> Enum.flat_map(fn {pos2, freq2} ->
      if pos1 != pos2 and freq1 == freq2, do: f.(pos1, pos2), else: []
    end)
  end)
  |> Enum.uniq()
  |> Enum.count()
end

part1 = count_antinodes.(get_antinodes)
part2 = count_antinodes.(points_in_line)

IO.puts("Part 1: #{part1}")
IO.puts("Part 1: #{part2}")
