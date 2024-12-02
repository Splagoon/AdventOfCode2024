reports =
  File.read!("data/02.txt")
  |> String.split(["\n", "\r\n"])
  |> Enum.map(fn report ->
    report
    |> String.split(" ")
    |> Enum.map(&String.to_integer/1)
  end)

is_safe = fn comp, row ->
  me = fn
    _f, _comp, [_] ->
      true

    f, comp, [head | [next | _] = tail] ->
      comp.(head, next) and abs(head - next) in 1..3 and f.(f, comp, tail)
  end

  me.(me, comp, row)
end

is_safe_increasing = fn row ->
  is_safe.(&</2, row)
end

is_safe_decreasing = fn row ->
  is_safe.(&>/2, row)
end

is_safe_dampened = fn row ->
  attempts = [
    row
    | for {_, i} <- Enum.with_index(row) do
        List.delete_at(row, i)
      end
  ]

  Enum.any?(attempts, fn attempt ->
    is_safe_increasing.(attempt) or is_safe_decreasing.(attempt)
  end)
end

part1 =
  reports
  |> Enum.count(fn report ->
    is_safe_increasing.(report) or is_safe_decreasing.(report)
  end)

part2 =
  reports
  |> Enum.count(is_safe_dampened)

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
