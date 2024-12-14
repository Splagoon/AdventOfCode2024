regex =
  ~r/Button A: X\+(\d+), Y\+(\d+)(?:\n|\r\n)Button B: X\+(\d+), Y\+(\d+)(?:\n|\r\n)Prize: X=(\d+), Y=(\d+)/

machines =
  File.read!("data/13.txt")
  |> String.split(["\n\n", "\r\n\r\n"])
  |> Enum.map(fn machine ->
    Regex.scan(regex, machine, capture: :all_but_first)
    |> List.first()
    |> Enum.map(&String.to_integer/1)
  end)

best_price_part1 = fn [ax, ay, bx, by, px, py] ->
  for a <- 0..100,
      b <- 0..100 do
    {a, b}
  end
  |> Enum.filter(fn {a, b} ->
    a * ax + b * bx == px and a * ay + b * by == py
  end)
  |> Enum.map(fn {a, b} -> a * 3 + b end)
  |> Enum.min(fn -> 0 end)
end

best_price_part2 = fn [ax, ay, bx, by, px, py] ->
  real_px = px + 10_000_000_000_000
  real_py = py + 10_000_000_000_000

  m1 = ay / ax
  b1 = 0

  m2 = by / bx
  b2 = -m2 * real_px + real_py

  ix = (b2 - b1) / (m1 - m2)

  a = round(ix / ax)
  b = round((real_px - ix) / bx)
  if a * ax + b * bx == real_px and a * ay + b * by == real_py, do: a * 3 + b
end

part1 =
  machines
  |> Enum.map(best_price_part1)
  |> Enum.sum()

part2 =
  machines
  |> Enum.map(best_price_part2)
  |> Enum.filter(&(not is_nil(&1)))
  |> Enum.sum()

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
