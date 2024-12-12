defmodule Day12 do
  def part_one(data) do
    data |> create_map() |> fence_regions() |> Enum.map(fn {_, a, fs} -> a * length(fs) end) |> Enum.sum()
  end

  def part_two(data) do
    data |> create_map() |> fence_regions() |> Enum.map(fn {_, a, fs} -> a * count_sides(fs) end) |> Enum.sum()
    # data |> create_map() |> fence_regions() |> Enum.map(fn {c, a, fs} -> {c, a, count_sides(fs)} end)
  end

  defp create_map(data) do
    for {line, y} <- data |> String.split() |> Enum.with_index(),
        {crop, x} <- line |> String.codepoints() |> Enum.with_index(),
        into: %{},
        do: {{x, y}, crop}
  end

  defp fence_regions(map), do: fence_regions(map, map, [])
  defp fence_regions(map, _, regions) when map_size(map) == 0, do: regions

  defp fence_regions(map, orig_map, regions) do
    with location <- map |> Map.keys() |> Enum.at(0),
         {crop, map} <- Map.pop!(map, location),
         {map, regions} <- fence_region([location], crop, 1, [], map, orig_map, regions) do
      fence_regions(map, orig_map, regions)
    end
  end

  defp fence_region(searchfront, crop, area, fences, map, orig_map, regions_builder)

  defp fence_region([], crop, area, fences, map, _, regions_builder),
    do: {map, [{crop, area, fences} | regions_builder]}

  defp fence_region([{x, y} | rest], crop, area, fences, map, orig_map, regions_builder) do
    with check <- [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}],
         added_plots <- Enum.filter(check, &(Map.get(map, &1) == crop)),
         added_fences <- calculate_fences({x, y}, crop, orig_map),
         updated_map <- Enum.reduce(added_plots, map, &Map.delete(&2, &1)) do
      fence_region(
        added_plots ++ rest,
        crop,
        area + length(added_plots),
        added_fences ++ fences,
        updated_map,
        orig_map,
        regions_builder
      )
    end
  end

  # Index each fencepost with the x-y coords of the plot it is the NW corner of. Then record fences as a tuple of
  # of its left post (standing inside the field), direction, and (for ease) its right post, plus a mark field which is false
  defp calculate_fences({x, y}, crop, map) do
    fences = []
    fences = if Map.get(map, {x - 1, y}) != crop, do: [{{x, y + 1}, :n, {x, y}, false} | fences], else: fences
    fences = if Map.get(map, {x + 1, y}) != crop, do: [{{x + 1, y}, :s, {x + 1, y + 1}, false} | fences], else: fences
    fences = if Map.get(map, {x, y - 1}) != crop, do: [{{x, y}, :e, {x + 1, y}, false} | fences], else: fences
    if Map.get(map, {x, y + 1}) != crop, do: [{{x + 1, y + 1}, :w, {x, y + 1}, false} | fences], else: fences
  end

  defp count_sides([]), do: 0

  defp count_sides(fences) do
    # Make sure we start just after a corner
    {first_fence, fences} = walk_side_and_turn(List.first(fences), fences, false)

    with {count, fences} <- count_sides(fences, first_fence, first_fence, 0) do
      fences = Enum.reject(fences, fn {_, _, _, marked} -> marked end)
      count + count_sides(fences)
    end
  end

  defp count_sides(fences, {x, y, d, true}, {x, y, d, false}, sides), do: {sides, fences}

  defp count_sides(fences, current_fence, start_fence, sides) do
    with {next_fence, fences} <- walk_side_and_turn(current_fence, fences) do
      count_sides(fences, next_fence, start_fence, sides + 1)
    end
  end

  defp walk_side_and_turn(fence = {left, dir, right, _}, fences, mark \\ true) do
    fence_index = Enum.find_index(fences, &(&1 == fence))
    coincident_fences = Enum.filter(fences, fn {next_left, _, _, _} -> next_left == right end)

    direction_order =
      case dir do
        :n -> [:e, :n, :w]
        :e -> [:s, :e, :n]
        :s -> [:w, :s, :e]
        :w -> [:n, :w, :s]
      end

    next_fence_dir =
      Enum.find(direction_order, &Enum.any?(coincident_fences, fn {_, next_dir, _, _} -> next_dir == &1 end))

    next_fence = Enum.find(coincident_fences, fn {_, next_dir, _, _} -> next_dir == next_fence_dir end)
    new_fences = List.update_at(fences, fence_index, fn _ -> {left, dir, right, true} end)

    if next_fence_dir == dir,
      do: walk_side_and_turn(next_fence, new_fences, mark),
      else: {next_fence, new_fences}
  end
end

# sample = "
# AAAA
# BBCD
# BBCC
# EEEC"
# sample = "RRRRIICCFF
# RRRRIICCCF
# VVRRRCCFFF
# VVRCCCJFFF
# VVVVCJJCFE
# VVIVCCJJEE
# VVIIICJJEE
# MIIIIIJJEE
# MIIISIJEEE
# MMMISSJEEE"
sample = "AAAAAA
AAABBA
AAABBA
ABBAAA
ABBAAA
AAAAAA"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day12.part_one(data))
IO.inspect(Day12.part_two(data))
