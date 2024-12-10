defmodule Day10 do
  def part_one(map) do
    with height_map <- parse_map(map),
         trailheads <- trailheads(height_map) do
      trailheads
      |> Enum.map(&trail_ends([{&1, 0}], height_map, MapSet.new()))
      |> Enum.map(&MapSet.size/1)
      |> Enum.sum()
    end
  end

  def part_two(map) do
    with height_map <- parse_map(map),
         trailheads <- trailheads(height_map) do
      trailheads
      |> Enum.map(&trail_ends([{&1, 0}], height_map, []))
      |> Enum.map(&length/1)
      |> Enum.sum()
    end
  end

  defp parse_map(map) do
    for {row, y} <- map |> String.split() |> Enum.with_index(),
        {cell, x} <- row |> String.codepoints() |> Enum.with_index(),
        reduce: %{} do
      height_map -> Map.put(height_map, {x, y}, String.to_integer(cell))
    end
  end

  defp trailheads(height_map) do
    height_map |> Enum.filter(&(elem(&1, 1) == 0)) |> Enum.map(&elem(&1, 0))
  end

  defp trail_ends([], _, builder), do: builder

  defp trail_ends([{location, 9} | rest], height_map, builder) when is_list(builder),
    do: trail_ends(rest, height_map, [location | builder])

  defp trail_ends([{location, 9} | rest], height_map, builder),
    do: trail_ends(rest, height_map, MapSet.put(builder, location))

  defp trail_ends([{{x, y}, height} | rest], height_map, builder) do
    new_steps =
      [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]
      |> Enum.filter(fn loc -> Map.get(height_map, loc) == height + 1 end)
      |> Enum.map(&{&1, height + 1})

    trail_ends(new_steps ++ rest, height_map, builder)
  end
end

sample = "89010123
78121874
87430965
96549874
45678903
32019012
01329801
10456732"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day10.part_one(data))
IO.inspect(Day10.part_two(data))
