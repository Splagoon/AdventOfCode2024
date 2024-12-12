require Integer

input =
  File.read!("data/11.txt")
  |> String.split(" ")
  |> Enum.map(&String.to_integer/1)

blink = fn stone ->
  digits = Integer.digits(stone)

  new_stones =
    cond do
      stone == 0 ->
        [1]

      Integer.is_even(length(digits)) ->
        Enum.split(digits, div(length(digits), 2))
        |> Tuple.to_list()
        |> Enum.map(&Integer.undigits/1)

      true ->
        [stone * 2024]
    end

  new_stones
end

blink_n = fn stone, n ->
  f = fn f, stone, n, num_stones, memory ->
    cond do
      n == 0 ->
        {num_stones, memory}

      Map.has_key?(memory, {stone, n}) ->
        {Map.get(memory, {stone, n}), memory}

      true ->
        for new_stone <- blink.(stone), reduce: {num_stones - 1, memory} do
          {num_stones, memory} ->
            {added_stones, new_memory} = f.(f, new_stone, n - 1, 1, memory)
            {num_stones + added_stones, Map.put(new_memory, {new_stone, n - 1}, added_stones)}
        end
    end
  end

  f.(f, stone, n, 1, %{})
  |> then(&elem(&1, 0))
end

part1 =
  input
  |> Enum.map(fn stone -> blink_n.(stone, 25) end)
  |> Enum.sum()

part2 =
  input
  |> Enum.map(fn stone -> blink_n.(stone, 75) end)
  |> Enum.sum()

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
