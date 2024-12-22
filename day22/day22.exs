defmodule Day22 do
  def part_one(data) do
    data
    |> String.split()
    |> Enum.map(fn str ->
      str |> String.to_integer() |> run_secret(0, 2000, %{}, []) |> elem(0)
    end)
    |> Enum.sum()
  end

  def part_two(data) do
    data
    |> String.split()
    |> Enum.map(&String.to_integer/1)
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {secret, ix}, search_map ->
      run_secret(secret, ix, 2000, search_map, [rem(secret, 10)]) |> elem(1)
    end)
    |> Map.values()
    |> Enum.map(fn bananas_map -> bananas_map |> Map.values() |> Enum.sum() end)
    |> Enum.max()
  end

  defp run_secret(prev, _, 0, search_map, _), do: {prev, search_map}

  defp run_secret(prev, ix, steps, search_map, last_digits) do
    last_digits =
      case last_digits do
        [head | rest] when length(rest) == 4 -> rest
        _ -> last_digits
      end

    # Step 1
    temp = prev * 64
    temp = Bitwise.bxor(temp, prev)
    prev = rem(temp, 16_777_216)

    # Step 2
    temp = div(prev, 32)
    temp = Bitwise.bxor(temp, prev)
    prev = rem(temp, 16_777_216)

    # Step 3
    temp = prev * 2048
    temp = Bitwise.bxor(temp, prev)
    temp = rem(temp, 16_777_216)

    last_digit = rem(temp, 10)
    last_digits = last_digits ++ [last_digit]
    diffs = last_digits |> Enum.chunk_every(2, 1, :discard) |> Enum.map(fn [a, b] -> b - a end)
    purchases = Map.get(search_map, diffs)

    search_map =
      case diffs do
        [_, _, _, _] when is_map(purchases) and not is_map_key(purchases, ix) ->
          Map.update(search_map, diffs, %{ix => last_digit}, fn purchases ->
            Map.put(purchases, ix, last_digit)
          end)

        [_, _, _, _] when not is_map(purchases) ->
          Map.put(search_map, diffs, %{ix => last_digit})

        _ ->
          search_map
      end

    run_secret(temp, ix, steps - 1, search_map, last_digits)
  end
end

sample = "1
10
100
2024"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day22.part_one(data))
IO.inspect(Day22.part_two(data))
