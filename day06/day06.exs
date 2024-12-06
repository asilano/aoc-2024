defmodule Day06 do
  def part_one(map) do
    map |> trodden_paths() |> Enum.uniq_by(fn {guard, facing} -> guard end) |> length()
  end

  def part_two(map) do
    # Only makes sense to obstruct a trodden path
    map
    |> trodden_paths()
    |> Enum.map(fn {guard, facing} -> guard end)
    |> Enum.uniq()
    |> Task.async_stream(fn possible -> trodden_paths(map, possible) end, ordered: false)
    |> Enum.count(fn {:ok, result} ->
      result == :loop
    end)
  end

  defp parse_map(map) do
    for {line, y} <- map |> String.split() |> Enum.with_index(),
        {cell, x} <- line |> String.codepoints() |> Enum.with_index(),
        reduce: {nil, %{}} do
      {guard, obstacles} ->
        case cell do
          "#" -> {guard, Map.put(obstacles, {x, y}, true)}
          "^" -> {{x, y}, obstacles}
          "." -> {guard, obstacles}
        end
    end
  end

  defp trodden_paths(map, extra_obstacle \\ nil) do
    with height <- map |> String.split() |> length(),
         width <- map |> String.codepoints() |> Enum.find_index(&(&1 == "\n")),
         {guard, obstacles} <- parse_map(map) do
      traceroute(guard, 0, -1, height, width, Map.put(obstacles, extra_obstacle, true), %{})
    end
  end

  defp traceroute(guard, dx, dy, height, width, obstacles, trodden)

  defp traceroute(guard, dx, dy, _, _, _, trodden) when is_map_key(trodden, {guard, {dx, dy}}),
    do: :loop

  defp traceroute({guard_x, guard_y}, _, _, height, width, _, trodden)
       when guard_x < 0 or guard_x >= width or guard_y < 0 or guard_y >= height,
       do: Map.keys(trodden)

  defp traceroute(guard = {guard_x, guard_y}, dx, dy, height, width, obstacles, trodden)
       when is_map_key(obstacles, {guard_x + dx, guard_y + dy}) do
    traceroute(
      guard,
      -dy,
      dx,
      height,
      width,
      obstacles,
      Map.put(trodden, {guard, {dx, dy}}, true)
    )
  end

  defp traceroute(guard = {guard_x, guard_y}, dx, dy, height, width, obstacles, trodden) do
    traceroute(
      {guard_x + dx, guard_y + dy},
      dx,
      dy,
      height,
      width,
      obstacles,
      Map.put(trodden, {guard, {dx, dy}}, true)
    )
  end
end

sample =
  """
  ....#.....
  .........#
  ..........
  ..#.......
  .......#..
  ..........
  .#..^.....
  ........#.
  #.........
  ......#...
  """
  |> String.trim()

data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day06.part_one(data))
IO.inspect(Day06.part_two(data))
