{start_pos, end_pos, map} =
  File.read!("data/16.txt")
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

move = fn {x, y}, dir ->
  case dir do
    :north -> {x, y - 1}
    :east -> {x + 1, y}
    :south -> {x, y + 1}
    :west -> {x - 1, y}
  end
end

opposite? = fn
  :north -> :south
  :south -> :north
  :east -> :west
  :west -> :east
end

graph =
  for pos <- Map.keys(map), reduce: [] do
    graph ->
      if Map.get(map, pos) == :wall do
        graph
      else
        for dir <- [:north, :east, :south, :west], reduce: graph do
          graph ->
            edges =
              for edge <- [:north, :east, :south, :west], reduce: [] do
                edges ->
                  cond do
                    dir == edge ->
                      forward = move.(pos, dir)

                      if Map.get(map, forward) == :wall,
                        do: edges,
                        else: [{{forward, dir}, 1} | edges]

                    dir != opposite?.(edge) ->
                      [{{pos, edge}, 1000} | edges]

                    true ->
                      edges
                  end
              end

            [{{pos, dir}, edges} | graph]
        end
      end
  end
  |> Enum.into(%{})

# Simple distance-squared heuristic
h = fn {{x, y}, _} ->
  {ex, ey} = end_pos
  (x - ex) * (x - ex) + (y - ey) * (y - ey)
end

inf = 999_999_999_999_999

get_paths = fn came_from, current ->
  keys = Map.keys(came_from)

  f = fn f, current, path ->
    if current in keys do
      new_currents = Map.get(came_from, current)

      for new_current <- new_currents, reduce: [] do
        found_paths ->
          f.(f, new_current, [new_current | path]) ++ found_paths
      end
    else
      path
    end
  end

  f.(f, current, [current])
end

a_star = fn ->
  f = fn f, open_set, came_from, g_score, f_score, best_score, best_came_from, best_ends ->
    if Enum.empty?(open_set) do
      {best_ends
       |> Enum.flat_map(&get_paths.(best_came_from, &1)), best_score}
    else
      current = Enum.min_by(open_set, &Map.get(f_score, &1, inf))

      if elem(current, 0) == end_pos do
        if best_score < 0 or best_score == Map.get(g_score, current) do
          f.(
            f,
            List.delete(open_set, current),
            came_from,
            g_score,
            f_score,
            Map.get(g_score, current),
            came_from,
            [current | best_ends]
          )
        else
          {best_ends
           |> Enum.flat_map(&get_paths.(best_came_from, &1)), best_score}
        end
      else
        {new_open_set, new_came_from, new_g_score, new_f_score} =
          for {neighbor, w} <- Map.get(graph, current),
              reduce: {List.delete(open_set, current), came_from, g_score, f_score} do
            {open_set, came_from, g_score, f_score} ->
              tentative_g_score = Map.get(g_score, current, inf) + w

              if tentative_g_score <= Map.get(g_score, neighbor, inf) do
                new_open_set = if(neighbor in open_set, do: open_set, else: [neighbor | open_set])

                new_came_from =
                  if tentative_g_score == Map.get(g_score, neighbor) do
                    Enum.uniq([current | Map.get(came_from, neighbor, [])])
                  else
                    [current]
                  end

                {new_open_set,
                 Map.put(
                   came_from,
                   neighbor,
                   new_came_from
                 ), Map.put(g_score, neighbor, tentative_g_score),
                 Map.put(f_score, neighbor, tentative_g_score + h.(neighbor))}
              else
                {open_set, came_from, g_score, f_score}
              end
          end

        f.(
          f,
          new_open_set,
          new_came_from,
          new_g_score,
          new_f_score,
          best_score,
          best_came_from,
          best_ends
        )
      end
    end
  end

  start = {start_pos, :east}
  f.(f, [start], %{}, %{start => 0}, %{start => h.(start)}, -1, nil, [])
end

{paths, part1} = a_star.()

part2 =
  paths
  |> Enum.map(&elem(&1, 0))
  |> Enum.uniq()
  |> Enum.count()

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
