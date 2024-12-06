{rules, updates} =
  File.read!("data/05.txt")
  |> String.split(["\n\n", "\r\n\r\n"])
  |> then(fn [rules_input, updates_input] ->
    rules =
      rules_input
      |> String.split(["\n", "\r\n"])
      |> Enum.map(fn rule ->
        rule |> String.split("|") |> Enum.map(&String.to_integer/1) |> List.to_tuple()
      end)

    updates =
      updates_input
      |> String.split(["\n", "\r\n"])
      |> Enum.map(fn update ->
        update |> String.split(",") |> Enum.map(&String.to_integer/1)
      end)

    {rules, updates}
  end)

rules_for = fn page ->
  rules
  |> Enum.filter(fn {a, _} -> a == page end)
  |> Enum.map(&elem(&1, 1))
end

is_valid = fn update ->
  update
  |> Enum.with_index()
  |> Enum.all?(fn {page, index} ->
    rules_for.(page)
    |> Enum.all?(fn dependent ->
      dep_index = Enum.find_index(update, &(&1 == dependent))
      is_nil(dep_index) or index < dep_index
    end)
  end)
end

fix_rule = fn update, {page, dep} ->
  page_idx = Enum.find_index(update, &(&1 == page))
  dep_idx = Enum.find_index(update, &(&1 == dep))

  case {page_idx, dep_idx} do
    # Rule doesn't apply
    {nil, _} ->
      update

    # Rule doesn't apply
    {_, nil} ->
      update

    # Already in order
    _ when page_idx < dep_idx ->
      update

    _ ->
      update
      |> List.delete_at(dep_idx)
      |> List.insert_at(page_idx, dep)
  end
end

fix_update = fn update ->
  iter = fn f, u ->
    fixed =
      for rule <- rules, reduce: u do
        fixed_update ->
          fix_rule.(fixed_update, rule)
      end

    if is_valid.(fixed), do: fixed, else: f.(f, fixed)
  end

  iter.(iter, update)
end

middle = fn list ->
  Enum.at(list, div(length(list), 2))
end

{correct, incorrect} = Enum.split_with(updates, is_valid)

part1 =
  correct
  |> Enum.map(middle)
  |> Enum.sum()

part2 =
  incorrect
  |> Enum.map(fn update ->
    update
    |> then(fix_update)
    |> then(middle)
  end)
  |> Enum.sum()

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
