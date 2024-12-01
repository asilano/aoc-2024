defmodule Day01 do
  def part_one(data) do
    with {list_one, list_two} <- parse(data) do
      Enum.zip(Enum.sort(list_one), Enum.sort(list_two))
      |> Enum.map(fn {l, r} -> abs(l - r) end)
      |> Enum.sum()
    end
  end

  def part_two(data) do
    with {list_one, list_two} <- parse(data),
         freqs = Enum.frequencies(list_two) do
      list_one |> Enum.map(fn elem -> elem * Map.get(freqs, elem, 0) end) |> Enum.sum()
    end
  end

  defp parse(data) do
    for line <- String.split(data, "\n"), reduce: {[], []} do
      {one, two} ->
        with [left, right] <- String.split(line) do
          {[String.to_integer(left) | one], [String.to_integer(right) | two]}
        end
    end
  end
end

sample = "3   4
4   3
2   5
1   3
3   9
3   3"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day01.part_one(data))
IO.inspect(Day01.part_two(data))
