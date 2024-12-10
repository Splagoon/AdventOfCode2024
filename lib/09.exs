{disk_map, last_file_id} =
  File.read!("data/09.txt")
  |> String.graphemes()
  |> Enum.reduce({[], 0, :file}, fn digit, {disk_map, next_id, state} ->
    n = String.to_integer(digit)

    case state do
      :file -> {disk_map ++ List.duplicate(next_id, n), next_id + 1, :free}
      :free -> {disk_map ++ List.duplicate(nil, n), next_id, :file}
    end
  end)
  |> then(fn {disk_map, next_id, _} ->
    {disk_map |> :array.from_list() |> :array.fix(), next_id - 1}
  end)

last_block_index = fn disk_map ->
  (:array.size(disk_map) - 1)..0//-1
  |> Enum.find(fn i -> not is_nil(:array.get(i, disk_map)) end)
end

compact_blocks = fn {id, index}, disk_map ->
  last_idx = last_block_index.(disk_map)

  cond do
    index > last_idx ->
      disk_map

    is_nil(id) ->
      # Swap last used block into this slot
      last_id = :array.get(last_idx, disk_map)

      disk_map
      |> then(&:array.set(index, last_id, &1))
      |> then(&:array.set(last_idx, nil, &1))

    true ->
      disk_map
  end
end

find_file_indexes = fn file_id, disk_map ->
  0..(:array.size(disk_map) - 1)
  |> Enum.filter(&(:array.get(&1, disk_map) == file_id))
end

find_free_space = fn size, disk_map ->
  0..(:array.size(disk_map) - size)
  |> Enum.find(fn i ->
    i..(i + size - 1)
    |> Enum.all?(&is_nil(:array.get(&1, disk_map)))
  end)
end

compact_file = fn file_id, disk_map ->
  file_indexes = find_file_indexes.(file_id, disk_map)
  file_size = length(file_indexes)
  free_space_idx = find_free_space.(file_size, disk_map)

  if is_nil(free_space_idx) or free_space_idx > List.first(file_indexes) do
    disk_map
  else
    for i <- free_space_idx..(free_space_idx + file_size - 1), reduce: disk_map do
      disk_map -> :array.set(i, file_id, disk_map)
    end
    |> then(
      &for i <- file_indexes, reduce: &1 do
        disk_map -> :array.set(i, nil, disk_map)
      end
    )
  end
end

checksum = fn disk_map ->
  0..(:array.size(disk_map) - 1)
  |> Enum.map(fn index ->
    id = :array.get(index, disk_map)
    if is_nil(id), do: 0, else: id * index
  end)
  |> Enum.sum()
end

part1 =
  0..(:array.size(disk_map) - 1)
  |> Enum.map(fn i -> {:array.get(i, disk_map), i} end)
  |> Enum.reduce(disk_map, compact_blocks)
  |> then(checksum)

part2 =
  last_file_id..0//-1
  |> Enum.reduce(disk_map, compact_file)
  |> then(checksum)

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
