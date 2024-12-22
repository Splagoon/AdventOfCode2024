codes =
  File.read!("data/21.txt")
  |> String.split(["\n", "\r\n"])
  |> Enum.map(fn code ->
    code
    |> String.graphemes()
    |> Enum.map(fn
      "A" -> :a
      num -> String.to_integer(num)
    end)
  end)

numeric_keypad = %{
  7 => {0, 0},
  8 => {1, 0},
  9 => {2, 0},
  4 => {0, 1},
  5 => {1, 1},
  6 => {2, 1},
  1 => {0, 2},
  2 => {1, 2},
  3 => {2, 2},
  0 => {1, 3},
  :a => {2, 3}
}

directional_keypad = %{
  :up => {1, 0},
  :a => {2, 0},
  :left => {0, 1},
  :down => {1, 1},
  :right => {2, 1}
}

seqs_to_key = fn keypad, {kx, ky}, {x, y} ->
  keypad_positions = keypad |> Map.values() |> MapSet.new()
  dx = if(kx > x, do: :right, else: :left)
  dy = if(ky > y, do: :down, else: :up)

  cond do
    kx == x and ky == y ->
      [[:a]]

    kx == x ->
      [List.duplicate(dy, abs(ky - y)) ++ [:a]]

    ky == y ->
      [List.duplicate(dx, abs(kx - x)) ++ [:a]]

    true ->
      x_list = List.duplicate(dx, abs(kx - x))
      y_list = List.duplicate(dy, abs(ky - y))

      cond do
        not MapSet.member?(keypad_positions, {kx, y}) ->
          [y_list ++ x_list ++ [:a]]

        not MapSet.member?(keypad_positions, {x, ky}) ->
          [x_list ++ y_list ++ [:a]]

        true ->
          [y_list ++ x_list ++ [:a], x_list ++ y_list ++ [:a]]
      end
  end
end

get_numeric_sequences = fn sequence ->
  f = fn f, sequence, pos, found ->
    case sequence do
      [] ->
        found

      [key | tail] ->
        key_pos = Map.get(numeric_keypad, key)

        seqs = seqs_to_key.(numeric_keypad, key_pos, pos)

        new_found =
          found
          |> Enum.flat_map(fn s -> Enum.map(seqs, &(&1 ++ s)) end)

        f.(f, tail, key_pos, new_found)
    end
  end

  f.(f, sequence, Map.get(numeric_keypad, :a), [[]])
end

expand_chunk = fn chunk ->
  for key <- chunk, reduce: {[[]], Map.get(directional_keypad, :a)} do
    {seq, pos} ->
      next_pos = Map.get(directional_keypad, key)

      seqs_to_key.(directional_keypad, next_pos, pos)
      |> Enum.flat_map(fn new_seq ->
        seq |> Enum.map(fn s -> s ++ new_seq end)
      end)
      |> then(&{&1, next_pos})
  end
  |> elem(0)
end

get_chunks = fn sequence ->
  sequence
  |> Enum.chunk_while(
    [],
    fn key, chunk ->
      case key do
        :a -> {:cont, Enum.reverse([key | chunk]), []}
        _ -> {:cont, [key | chunk]}
      end
    end,
    fn acc -> {:cont, acc} end
  )
end

process_chunk = fn chunk, n, m ->
  f = fn f, chunk, n, m ->
    cond do
      Map.has_key?(m, {chunk, n}) ->
        {Map.get(m, {chunk, n}), m}

      n == 0 ->
        {length(chunk), m}

      true ->
        {res, new_m} =
          for expansion <- chunk |> expand_chunk.(), reduce: {[], m} do
            {sizes, m} ->
              for subchunk <- get_chunks.(expansion), reduce: {0, m} do
                {smallest_chunk, m} ->
                  {chunk_size, new_m} = f.(f, subchunk, n - 1, m)

                  {smallest_chunk + chunk_size, new_m}
              end
              |> then(fn {chunk_size, new_m} ->
                {[chunk_size | sizes], new_m}
              end)
          end
          |> then(fn {sizes, m} ->
            {Enum.min(sizes), m}
          end)

        {res, Map.put(new_m, {chunk, n}, res)}
    end
  end

  f.(f, chunk, n, m)
end

complexity = fn len, code ->
  code_value = Integer.undigits(Enum.take(code, length(code) - 1))
  IO.puts("#{code_value} * #{len}")
  code_value * len
end

run_robots = fn code, n ->
  starting_seqs =
    get_numeric_sequences.(code)

  for seq <- starting_seqs, reduce: {-1, %{}} do
    {res, m} ->
      {n, new_m} =
        process_chunk.(seq, n, m)

      {if(res < 0 or n < res, do: n, else: res), new_m}
  end
  |> elem(0)
  |> complexity.(code)
end

part1 =
  codes
  |> Enum.map(&run_robots.(&1, 2))
  |> Enum.sum()

IO.puts("Part 1: #{part1}")

part2 =
  codes
  |> Enum.map(&run_robots.(&1, 25))
  |> Enum.sum()

IO.puts("Part 2: #{part2}")
