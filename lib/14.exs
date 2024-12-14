regex = ~r/p=(\d+),(\d+) v=(-?\d+),(-?\d+)/

{map_width, map_height} = {101, 103}

robots =
  File.read!("data/14.txt")
  |> String.split(["\n", "\r\n"])
  |> Enum.map(fn robot ->
    Regex.scan(regex, robot, capture: :all_but_first)
    |> List.first()
    |> Enum.map(&String.to_integer/1)
    |> then(fn [px, py, vx, vy] -> {{px, py}, {vx, vy}} end)
  end)

move_1 = fn {px, py}, {vx, vy} ->
  {Integer.mod(px + vx, map_width), Integer.mod(py + vy, map_height)}
end

move_n = fn {pos, vel}, n ->
  for _ <- 1..n, reduce: pos do
    pos -> move_1.(pos, vel)
  end
end

quadrant = fn {x, y} ->
  {cx, cy} = {div(map_width, 2), div(map_height, 2)}

  cond do
    x < cx and y < cy -> 1
    x > cx and y < cy -> 2
    x < cx and y > cy -> 3
    x > cx and y > cy -> 4
    true -> 0
  end
end

is_in_tree_shape = fn {{x, y}, _} ->
  cx = div(map_width, 2)

  case quadrant.({x, y}) do
    0 -> true
    1 -> cx - x <= y
    2 -> x - cx <= y
    3 -> false
    4 -> false
  end
end

print_robots = fn robots ->
  robot_set = MapSet.new(robots |> Enum.map(&elem(&1, 0)))

  for y <- 0..(map_height - 1) do
    for x <- 0..(map_width - 1), reduce: "" do
      str -> str <> if MapSet.member?(robot_set, {x, y}), do: "#", else: "."
    end
    |> IO.puts()
  end
end

# The assumption here is completely wrong but gets the right answer
seek_tree_shape = fn ->
  f = fn f, robots, n ->
    count = Enum.count(robots, is_in_tree_shape)
    # Let's say "most" is like...45%
    if count / length(robots) >= 0.45 do
      print_robots.(robots)
      n
    else
      f.(
        f,
        Enum.map(robots, fn {pos, vel} ->
          {move_1.(pos, vel), vel}
        end),
        n + 1
      )
    end
  end

  f.(f, robots, 0)
end

part1 =
  robots
  |> Enum.map(&move_n.(&1, 100))
  |> Enum.group_by(quadrant)
  |> Map.delete(0)
  |> Map.values()
  |> Enum.map(&length/1)
  |> Enum.reduce(&*/2)

part2 = seek_tree_shape.()

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
