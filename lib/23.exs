connections =
  File.read!("data/23.txt")
  |> String.split(["\n", "\r\n"])
  |> Enum.map(fn line ->
    line
    |> String.split("-")
    |> then(fn [a, b] -> %{a => MapSet.new([b]), b => MapSet.new([a])} end)
  end)
  |> Enum.reduce(fn m1, m2 ->
    Map.merge(m1, m2, fn _, a, b ->
      MapSet.union(a, b)
    end)
  end)

get_largest_group = fn ->
  f = fn f, open_set, longest_found, already_tried ->
    case open_set do
      [] ->
        longest_found

      [{computer, group} | tail] ->
        new_group = Enum.sort([computer | group])

        candidates =
          new_group
          |> Enum.map(&Map.get(connections, &1))
          |> Enum.reduce(&MapSet.intersection/2)
          |> Enum.map(&{&1, new_group})

        cond do
          MapSet.member?(already_tried, new_group) ->
            f.(f, tail, longest_found, already_tried)

          length(candidates) + length(new_group) < length(longest_found) ->
            # Impossible for this candidate to exceed the longest length
            f.(f, tail, longest_found, already_tried)

          Enum.empty?(candidates) ->
            new_tried = MapSet.put(already_tried, new_group)

            if length(new_group) > length(longest_found),
              do: f.(f, tail, new_group, new_tried),
              else: f.(f, tail, longest_found, new_tried)

          true ->
            f.(f, candidates ++ tail, longest_found, MapSet.put(already_tried, new_group))
        end
    end
  end

  f.(f, Map.keys(connections) |> Enum.map(&{&1, []}), [], MapSet.new())
end

groups_of_3 =
  for {c1, c1_conn} <- Map.to_list(connections), reduce: [] do
    groups ->
      new_groups =
        c1_conn
        |> Enum.flat_map(fn c2 ->
          c2_conn = Map.get(connections, c2)

          MapSet.intersection(c1_conn, c2_conn)
          |> MapSet.delete(c1)
          |> MapSet.delete(c2)
          |> Enum.map(fn c3 -> [c2, c3] end)
        end)
        |> Enum.map(fn group -> Enum.sort([c1 | group]) end)

      new_groups ++ groups
  end
  |> Enum.uniq()

part1 =
  groups_of_3
  |> Enum.count(fn group ->
    Enum.any?(group, &String.starts_with?(&1, "t"))
  end)

part2 =
  get_largest_group.()
  |> Enum.join(",")

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
