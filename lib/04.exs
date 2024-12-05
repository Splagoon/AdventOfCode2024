input =
  File.read!("data/04.txt")
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

move = fn {x, y}, {dx, dy} -> {x + dx, y + dy} end

seek_word = fn start_pos, delta, letters ->
  me = fn f, pos, letters ->
    case letters do
      [] ->
        1

      [letter | tail] ->
        case Map.get(input, pos) do
          ^letter ->
            f.(f, move.(pos, delta), tail)

          _ ->
            0
        end
    end
  end

  me.(me, start_pos, letters)
end

seek_x_mas = fn start_pos ->
  letters = ["M", "A", "S"]

  found =
    [
      seek_word.(move.(start_pos, {-1, -1}), {1, 1}, letters),
      seek_word.(move.(start_pos, {-1, 1}), {1, -1}, letters),
      seek_word.(move.(start_pos, {1, -1}), {-1, 1}, letters),
      seek_word.(move.(start_pos, {1, 1}), {-1, -1}, letters)
    ]
    |> Enum.sum()

  if(found == 2, do: 1, else: 0)
end

part1 =
  input
  |> Map.keys()
  |> Enum.flat_map(fn pos ->
    [{-1, 0}, {-1, -1}, {0, -1}, {1, -1}, {1, 0}, {1, 1}, {0, 1}, {-1, 1}]
    |> Enum.map(fn delta ->
      seek_word.(pos, delta, ["X", "M", "A", "S"])
    end)
  end)
  |> Enum.sum()

part2 =
  input
  |> Map.keys()
  |> Enum.map(seek_x_mas)
  |> Enum.sum()

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
