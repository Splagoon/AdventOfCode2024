defmodule Day04 do
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

  def generate_obstacles({guard_pos, _}, map) do
    for {pos, what} <- Map.to_list(map), reduce: [] do
      maps ->
        cond do
          pos == guard_pos -> maps
          what == :wall -> maps
          what == :free -> [%{map | pos => :wall} | maps]
        end
    end
  end
end

{guard, map} = Day04.get_input()

part1 =
  Day04.walk(guard, map)
  |> then(&elem(&1, 1))
  |> MapSet.to_list()
  |> Enum.uniq_by(fn {pos, _} -> pos end)
  |> Enum.count()

part2 =
  Day04.generate_obstacles(guard, map)
  |> Enum.map(fn m -> Day04.walk(guard, m) end)
  |> Enum.count(&elem(&1, 0))

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
