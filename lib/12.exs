garden =
  File.read!("data/12.txt")
  |> String.split(["\n", "\r\n"])
  |> Enum.with_index()
  |> Enum.flat_map(fn {row, row_index} ->
    row
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.map(fn {col, col_index} ->
      {{col_index, row_index}, col}
    end)
  end)
  |> Enum.into(%{})

defmodule Day12 do
  defp scan_plot(_plant, [], map, plot), do: {map, plot}

  defp scan_plot(plant, [pos = {x, y} | tail], map, plot) do
    if Map.get(map, pos) == plant do
      scan_plot(
        plant,
        [
          {x - 1, y},
          {x + 1, y},
          {x, y - 1},
          {x, y + 1}
        ] ++ tail,
        Map.delete(map, pos),
        [pos | plot]
      )
    else
      scan_plot(plant, tail, map, plot)
    end
  end

  defp scan_plots(map, plots) do
    case Map.keys(map) do
      [] ->
        plots

      [pos | _] ->
        {new_map, plot} = scan_plot(Map.get(map, pos), [pos], map, [])
        scan_plots(new_map, [plot | plots])
    end
  end

  def get_plots(map), do: scan_plots(map, [])

  def area(plot), do: length(plot)

  defp get_exposed_sides({x, y}, plot_set) do
    [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]
    |> Enum.filter(fn pos -> not MapSet.member?(plot_set, pos) end)
  end

  def perimeter(plot) do
    plot_set = MapSet.new(plot)

    plot
    |> Enum.map(fn pos -> get_exposed_sides(pos, plot_set) |> Enum.count() end)
    |> Enum.sum()
  end

  # Observation: The number of corners equals the number of sides
  def corners(plot) do
    plot_set = MapSet.new(plot)

    plot
    |> Enum.map(fn pos = {x, y} ->
      outside_corners =
        case get_exposed_sides(pos, plot_set) do
          # That's a square!
          [_, _, _, _] -> 4
          # 2 corners
          [_, _, _] -> 2
          # 1 corner (making sure they're not opposite sides)
          [{ax, ay}, {bx, by}] when ax != bx and ay != by -> 1
          # Not an outside corner
          _ -> 0
        end

      inside_corners =
        [
          # Top left
          [{x - 1, y}, {x, y - 1}, {x - 1, y - 1}],
          # Top right
          [{x, y - 1}, {x + 1, y}, {x + 1, y - 1}],
          # Bottom right
          [{x + 1, y}, {x, y + 1}, {x + 1, y + 1}],
          # Bottom left
          [{x - 1, y}, {x, y + 1}, {x - 1, y + 1}]
        ]
        |> Enum.count(fn points ->
          case Enum.map(points, &MapSet.member?(plot_set, &1)) do
            [true, true, false] -> true
            _ -> false
          end
        end)

      outside_corners + inside_corners
    end)
    |> Enum.sum()
  end
end

plots = Day12.get_plots(garden)

part1 =
  plots
  |> Enum.map(fn plot -> Day12.area(plot) * Day12.perimeter(plot) end)
  |> Enum.sum()

part2 =
  plots
  |> Enum.map(fn plot -> Day12.area(plot) * Day12.corners(plot) end)
  |> Enum.sum()

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
