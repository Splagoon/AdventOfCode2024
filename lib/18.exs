grid_size = 70

bytes =
  File.read!("data/18.txt")
  |> String.split(["\n", "\r\n"])
  |> Enum.map(fn row ->
    row
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
    |> then(fn [x, y] -> {x, y} end)
  end)

h = fn {x, y} -> grid_size - x + (grid_size - y) end

inf = 999_999_999

get_path = fn came_from, current ->
  keys = Map.keys(came_from)

  f = fn f, current, path ->
    if current in keys do
      new_current = Map.get(came_from, current)
      f.(f, new_current, [new_current | path])
    else
      path
    end
  end

  f.(f, current, [])
end

neighbors = fn {x, y}, corrupted ->
  [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]
  |> Enum.filter(fn pos = {x, y} ->
    x in 0..grid_size and y in 0..grid_size and not MapSet.member?(corrupted, pos)
  end)
end

a_star = fn corrupted ->
  f = fn f, open_set, came_from, g_score, f_score ->
    if Enum.empty?(open_set) do
      :unreachable
    else
      current = Enum.min_by(open_set, &Map.get(f_score, &1, inf))

      if current == {grid_size, grid_size} do
        get_path.(came_from, current)
      else
        {new_open_set, new_came_from, new_g_score, new_f_score} =
          for neighbor <- neighbors.(current, corrupted),
              reduce: {List.delete(open_set, current), came_from, g_score, f_score} do
            {open_set, came_from, g_score, f_score} ->
              tentative_g_score = Map.get(g_score, current, inf) + 1

              if tentative_g_score < Map.get(g_score, neighbor, inf) do
                new_open_set = if(neighbor in open_set, do: open_set, else: [neighbor | open_set])

                {new_open_set, Map.put(came_from, neighbor, current),
                 Map.put(g_score, neighbor, tentative_g_score),
                 Map.put(f_score, neighbor, tentative_g_score + h.(neighbor))}
              else
                {open_set, came_from, g_score, f_score}
              end
          end

        f.(f, new_open_set, new_came_from, new_g_score, new_f_score)
      end
    end
  end

  start = {0, 0}
  f.(f, [start], %{}, %{start => 0}, %{start => h.(start)})
end

part1 =
  bytes
  |> Enum.take(1024)
  |> Enum.into(MapSet.new())
  |> a_star.()
  |> Enum.count()

part2 = fn f, n ->
  bytes = Enum.take(bytes, n)

  res =
    bytes
    |> Enum.into(MapSet.new())
    |> a_star.()

  if res == :unreachable do
    {x, y} = List.last(bytes)
    "#{x},#{y}"
  else
    f.(f, n + 1)
  end
end

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2.(part2, 1025)}")
