{towels, patterns} =
  File.read!("data/19.txt")
  |> String.split(["\n\n", "\r\n\r\n"])
  |> then(fn [towels, patterns] ->
    {String.split(towels, ", "), String.split(patterns, ["\n", "\r\n"])}
  end)

find_arrangements = fn pattern ->
  f = fn f, pattern, m ->
    if Map.has_key?(m, pattern) do
      {Map.get(m, pattern), m}
    else
      g = fn g, towels, found, m ->
        case towels do
          [] ->
            {found, Map.put(m, pattern, found)}

          [towel | rest_towels] ->
            case pattern do
              ^towel ->
                g.(g, rest_towels, found + 1, m)

              <<^towel::binary, rest_pattern::binary>> ->
                {new_found, new_m} = f.(f, rest_pattern, m)
                g.(g, rest_towels, new_found + found, new_m)

              _ ->
                g.(g, rest_towels, found, m)
            end
        end
      end

      g.(g, towels, 0, m)
    end
  end

  {result, _} = f.(f, pattern, %{})
  result
end

arrangements =
  for pattern <- patterns, into: %{} do
    a = find_arrangements.(pattern)
    {pattern, a}
  end

part1 =
  arrangements
  |> Map.values()
  |> Enum.count(&(&1 > 0))

part2 =
  arrangements
  |> Map.values()
  |> Enum.sum()

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
