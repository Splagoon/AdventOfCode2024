map =
  File.read!("data/10.txt")
  |> String.split(["\n", "\r\n"])
  |> Enum.with_index()
  |> Enum.flat_map(fn {row, row_index} ->
    row
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.map(fn {col, col_index} ->
      {{col_index, row_index}, String.to_integer(col)}
    end)
  end)
  |> Enum.into(%{})

trailheads =
  map
  |> Enum.filter(fn {_, height} -> height == 0 end)
  |> Enum.map(&elem(&1, 0))

get_higher_neighbors = fn {x, y}, height ->
  [{x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1}]
  |> Enum.map(&{&1, Map.get(map, &1)})
  |> Enum.filter(fn {_, h} -> h == height + 1 end)
end

search_trails = fn trailhead ->
  search = fn f, search_positions, peaks ->
    case search_positions do
      [] -> peaks
      [{pos, 9} | tail] -> f.(f, tail, [pos | peaks])
      [{pos, height} | tail] -> f.(f, get_higher_neighbors.(pos, height) ++ tail, peaks)
    end
  end

  search.(search, [{trailhead, 0}], [])
end

all_trails =
  trailheads
  |> Enum.map(&search_trails.(&1))

part1 =
  all_trails
  |> Enum.map(
    &(&1
      |> Enum.uniq()
      |> Enum.count())
  )
  |> Enum.sum()

part2 =
  all_trails
  |> Enum.map(&Enum.count(&1))
  |> Enum.sum()

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
