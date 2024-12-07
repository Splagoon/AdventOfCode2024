defmodule Day06 do
  def get_input() do
    File.read!("data/06.txt")
    |> String.split(["\n", "\r\n"])
    |> Enum.with_index()
    |> Enum.flat_map(fn {row, row_index} ->
      row
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.map(fn {col, col_index} -> {col, col_index, row_index} end)
    end)
    |> Enum.reduce({nil, %{}}, fn {col, col_index, row_index}, {guard, map} ->
      case col do
        "." -> {guard, Map.put(map, {col_index, row_index}, :free)}
        "#" -> {guard, Map.put(map, {col_index, row_index}, :wall)}
        "^" -> {{{col_index, row_index}, :north}, Map.put(map, {col_index, row_index}, :free)}
      end
    end)
  end

  defp move({pos_x, pos_y}, dir) do
    case dir do
      :north -> {pos_x, pos_y - 1}
      :south -> {pos_x, pos_y + 1}
      :east -> {pos_x + 1, pos_y}
      :west -> {pos_x - 1, pos_y}
    end
  end

  defp turn(dir) do
    case dir do
      :north -> :east
      :east -> :south
      :south -> :west
      :west -> :north
    end
  end

  defp step({guard_pos, guard_dir}, map, visited) do
    next_pos = move(guard_pos, guard_dir)

    if MapSet.member?(visited, {next_pos, guard_dir}) do
      {true, visited}
    else
      case Map.get(map, next_pos) do
        :free ->
          step({next_pos, guard_dir}, map, MapSet.put(visited, {next_pos, guard_dir}))

        :wall ->
          next_dir = turn(guard_dir)
          step({guard_pos, next_dir}, map, MapSet.put(visited, {guard_pos, next_dir}))

        nil ->
          {false, visited}
      end
    end
  end

  def walk(guard, map), do: step(guard, map, MapSet.new([guard]))

  def generate_obstacles({guard_pos, _}, map, obstacle_positions) do
    for pos <- obstacle_positions, reduce: [] do
      maps ->
        what = Map.get(map, pos)

        cond do
          pos == guard_pos -> maps
          what == :wall -> maps
          what == :free -> [%{map | pos => :wall} | maps]
        end
    end
  end
end

{guard, map} = Day06.get_input()

guard_visited =
  Day06.walk(guard, map)
  |> then(&elem(&1, 1))
  |> MapSet.to_list()
  |> Enum.map(&elem(&1, 0))
  |> Enum.uniq()

part1 =
  guard_visited
  |> Enum.count()

part2 =
  Day06.generate_obstacles(guard, map, guard_visited)
  |> Enum.map(fn m -> Day06.walk(guard, m) end)
  |> Enum.count(&elem(&1, 0))

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
