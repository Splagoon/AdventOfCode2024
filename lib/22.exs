secrets =
  File.read!("data/22.txt")
  |> String.split(["\n", "\r\n"])
  |> Enum.map(&String.to_integer/1)

mix = fn a, b -> Bitwise.bxor(a, b) end
prune = fn a -> rem(a, 16_777_216) end

next = fn secret ->
  secret
  |> then(&mix.(&1 * 64, &1))
  |> prune.()
  |> then(&mix.(div(&1, 32), &1))
  |> prune.()
  |> then(&mix.(&1 * 2048, &1))
  |> prune.()
end

price = fn secret -> rem(secret, 10) end

secret_sequences =
  secrets
  |> Enum.map(fn secret ->
    Stream.unfold(secret, fn secret ->
      new_secret = next.(secret)
      {{new_secret, price.(new_secret), price.(new_secret) - price.(secret)}, new_secret}
    end)
    |> Enum.take(2000)
  end)

seqs_of_four =
  secret_sequences
  |> Enum.flat_map(fn seq -> Enum.map(seq, fn {_, _, change} -> change end) end)
  |> then(fn changes ->
    f = fn f, changes, seqs ->
      case changes do
        [one | tail = [two, three, four | _]] ->
          f.(f, tail, [[four, three, two, one] | seqs])

        _ ->
          seqs
      end
    end

    f.(f, changes, [])
  end)
  |> Enum.uniq()

price_maps =
  secret_sequences
  |> Enum.map(fn seq ->
    f = fn f, s, m ->
      case s do
        [{_, _, c1} | tail = [{_, _, c2}, {_, _, c3}, {_, price, c4} | _]] ->
          f.(f, tail, Map.put_new(m, [c1, c2, c3, c4], price))

        _ ->
          m
      end
    end

    f.(f, seq, %{})
  end)

part1 =
  secret_sequences
  |> Enum.map(&(List.last(&1) |> elem(0)))
  |> Enum.sum()

part2 =
  seqs_of_four
  |> Enum.map(fn seq ->
    price_maps
    |> Enum.map(&Map.get(&1, seq, 0))
    |> Enum.sum()
  end)
  |> Enum.max()

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
