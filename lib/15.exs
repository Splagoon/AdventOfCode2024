parse_map = fn string ->
  string
  |> String.split(["\n", "\r\n"])
  |> Enum.with_index()
  |> Enum.flat_map(fn {row, row_index} ->
    row
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.map(fn {col, col_index} ->
      {{col_index, row_index},
       case col do
         "#" -> :wall
         "." -> :free
         "O" -> :box
         "@" -> :robot
       end}
    end)
  end)
  |> Enum.into(%{})
end

widen_map = fn map ->
  map
  |> Map.to_list()
  |> Enum.flat_map(fn {{x, y}, what} ->
    {left, right} =
      case what do
        :wall -> {:wall, :wall}
        :free -> {:free, :free}
        :box -> {:box_left, :box_right}
        :robot -> {:robot, :free}
      end

    [{{x * 2, y}, left}, {{x * 2 + 1, y}, right}]
  end)
  |> Map.new()
end

parse_moves = fn string ->
  string
  |> String.replace(["\n", "\r\n"], "")
  |> String.graphemes()
  |> Enum.map(fn
    "<" -> :left
    "^" -> :up
    ">" -> :right
    "v" -> :down
  end)
end

{map, moves} =
  File.read!("data/15.txt")
  |> String.split(["\n\n", "\r\n\r\n"])
  |> then(fn [map, moves] -> {parse_map.(map), parse_moves.(moves)} end)

move_pos = fn {x, y}, dir ->
  case dir do
    :left -> {x - 1, y}
    :up -> {x, y - 1}
    :right -> {x + 1, y}
    :down -> {x, y + 1}
  end
end

try_move = fn pos, dir, map ->
  f = fn f, pos, dir, map ->
    next_pos = move_pos.(pos, dir)

    {can_move, map} =
      case Map.get(map, next_pos) do
        :free ->
          {true, map}

        :wall ->
          {false, map}

        :box ->
          case f.(f, next_pos, dir, map) do
            {:ok, _, new_map} -> {true, new_map}
            {:nok, _, _} -> {false, map}
          end

        box_half when box_half in [:box_left, :box_right] ->
          other_half = move_pos.(next_pos, if(box_half == :box_left, do: :right, else: :left))

          case f.(f, other_half, dir, map) do
            {:ok, _, new_map} ->
              case f.(f, next_pos, dir, new_map) do
                {:ok, _, new_map} -> {true, new_map}
                {:nok, _, _} -> {false, map}
              end

            {:nok, _, _} ->
              {false, map}
          end
      end

    if can_move do
      token = Map.get(map, pos)
      new_map = map |> Map.put(pos, :free) |> Map.put(next_pos, token)
      {:ok, next_pos, new_map}
    else
      {:nok, pos, map}
    end
  end

  {_, new_pos, new_map} = f.(f, pos, dir, map)
  {new_pos, new_map}
end

gps = fn {x, y} -> y * 100 + x end

robot_pos = fn map ->
  map
  |> Map.keys()
  |> Enum.find(fn pos -> Map.get(map, pos) == :robot end)
end

run = fn map ->
  for move <- moves, reduce: {robot_pos.(map), map} do
    {pos, map} ->
      try_move.(pos, move, map)
  end
  |> then(&elem(&1, 1))
  |> Map.filter(fn {_, what} -> what in [:box, :box_left] end)
  |> Map.keys()
  |> Enum.map(gps)
  |> Enum.sum()
end

part1 = run.(map)
part2 = run.(widen_map.(map))

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
