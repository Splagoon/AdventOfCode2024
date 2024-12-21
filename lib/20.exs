{start_pos, end_pos, map} =
  File.read!("data/20.txt")
  |> String.split(["\n", "\r\n"])
  |> Enum.with_index()
  |> Enum.reduce({nil, nil, Map.new()}, fn {row, row_index}, {start_pos, end_pos, map} ->
    for {col, col_index} <- row |> String.graphemes() |> Enum.with_index(),
        reduce: {start_pos, end_pos, map} do
      {start_pos, end_pos, map} ->
        pos = {col_index, row_index}

        case col do
          "#" -> {start_pos, end_pos, Map.put(map, pos, :wall)}
          "." -> {start_pos, end_pos, Map.put(map, pos, :free)}
          "S" -> {pos, end_pos, Map.put(map, pos, :free)}
          "E" -> {start_pos, pos, Map.put(map, pos, :free)}
        end
    end
  end)

base_graph =
  for pos = {x, y} <- Map.keys(map), reduce: %{} do
    graph ->
      if Map.get(map, pos) == :wall do
        graph
      else
        edges =
          [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]
          |> Enum.filter(fn p -> Map.get(map, p) == :free end)

        Map.put(graph, pos, edges)
      end
  end

dist = fn {x1, y1}, {x2, y2} ->
  abs(x1 - x2) + abs(y1 - y2)
end

cheats = fn radius ->
  for {pos1 = {x1, y1}, what1} <- Map.to_list(map), reduce: [] do
    found1 ->
      if what1 == :wall do
        found1
      else
        for x2 <- (x1 - radius)..(x1 + radius), y2 <- (y1 - radius)..(y1 + radius), reduce: [] do
          found2 ->
            pos2 = {x2, y2}
            what2 = Map.get(map, pos2)
            d = dist.(pos1, pos2)

            cond do
              what2 != :free -> found2
              d not in 2..radius -> found2
              true -> [{pos1, pos2} | found2]
            end
        end ++ found1
      end
  end
end

inf = 999_999_999

a_star = fn graph ->
  f = fn f, open_set, came_from, g_score, f_score ->
    current = Enum.min_by(open_set, &Map.get(f_score, &1, inf))

    if current == end_pos do
      g_score
    else
      {new_open_set, new_came_from, new_g_score, new_f_score} =
        for n <- Map.get(graph, current),
            reduce: {List.delete(open_set, current), came_from, g_score, f_score} do
          {open_set, came_from, g_score, f_score} ->
            tentative_g_score = Map.get(g_score, current, inf) + 1

            if tentative_g_score < Map.get(g_score, n, inf) do
              new_open_set = if(n in open_set, do: open_set, else: [n | open_set])

              {new_open_set, Map.put(came_from, n, current),
               Map.put(g_score, n, tentative_g_score),
               Map.put(f_score, n, tentative_g_score + dist.(n, end_pos))}
            else
              {open_set, came_from, g_score, f_score}
            end
        end

      f.(f, new_open_set, new_came_from, new_g_score, new_f_score)
    end
  end

  f.(f, [start_pos], %{}, %{start_pos => 0}, %{start_pos => dist.(start_pos, end_pos)})
end

g_score = a_star.(base_graph)

get_cheat_savings = fn {start, stop} ->
  Map.get(g_score, stop) - Map.get(g_score, start) - dist.(start, stop)
end

part1 =
  cheats.(2)
  |> Enum.map(get_cheat_savings)
  |> Enum.count(&(&1 >= 100))

part2 =
  cheats.(20)
  |> Enum.map(get_cheat_savings)
  |> Enum.count(&(&1 >= 100))

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
