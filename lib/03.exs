memory = File.read!("data/03.txt")

mul_regex = ~r/(do)\(\)|(don't)\(\)|mul\((\d{1,3})\,(\d{1,3})\)/

instructions =
  mul_regex
  |> Regex.scan(memory, capture: :all_but_first)
  |> Enum.map(fn
    ["do"] -> :enable
    [_, "don't"] -> :disable
    [_, _, a, b] -> {String.to_integer(a), String.to_integer(b)}
  end)

IO.puts(inspect(instructions))

part1 =
  instructions
  |> Enum.filter(&is_tuple/1)
  |> Enum.map(fn {a, b} -> a * b end)
  |> Enum.sum()

part2 =
  for instruction <- instructions, reduce: {0, :enable} do
    {sum, state} ->
      case {instruction, state} do
        {{a, b}, :enable} -> {sum + a * b, :enable}
        {{_a, _b}, :disable} -> {sum, :disable}
        {:enable, _} -> {sum, :enable}
        {:disable, _} -> {sum, :disable}
      end
  end
  |> elem(0)

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
