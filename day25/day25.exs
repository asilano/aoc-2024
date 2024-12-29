defmodule Day25 do
  def part_one(data) do
    grids = String.split(data, "\n\n")
    {locks, keys} = parse_grids(grids, [], [])
    check_fits(locks, keys)
  end

  defp parse_grids([], locks, keys), do: {locks, keys}

  defp parse_grids([grid | rest], locks, keys) do
    rows = grid |> String.split() |> Enum.map(&String.codepoints/1)

    columns =
      Enum.map(0..4, fn col ->
        Enum.map(rows, &Enum.at(&1, col)) |> Enum.filter(&(&1 == "#")) |> Enum.count() |> then(&(&1 - 1))
      end)

    if List.first(rows) == ["#", "#", "#", "#", "#"] do
      parse_grids(rest, [columns | locks], keys)
    else
      parse_grids(rest, locks, [columns | keys])
    end
  end

  defp check_fits(locks, keys) do
    for lock <- locks, key <- keys do
      Enum.zip(lock, key) |> Enum.all?(fn {l, k} -> l + k < 6 end)
    end
    |> Enum.count(& &1)
  end
end

sample = "#####
.####
.####
.####
.#.#.
.#...
.....

#####
##.##
.#.##
...##
...#.
...#.
.....

.....
#....
#....
#...#
#.#.#
#.###
#####

.....
.....
#.#..
###..
###.#
###.#
#####

.....
.....
.....
#....
#.#..
#.#.#
#####"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day25.part_one(data))
