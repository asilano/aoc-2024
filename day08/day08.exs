defmodule Day08 do
  def part_one(map) do
    {width, height, towers} = parse_map(map)

    antinodes(towers)
    |> List.flatten()
    |> Enum.filter(fn {x, y} -> x < width && x >= 0 && y < height && y >= 0 end)
    |> Enum.uniq()
    |> length()
  end

  def part_two(map) do
    {width, height, towers} = parse_map(map)

    harmonic_antinodes(towers, width, height)
    |> List.flatten()
    |> Enum.filter(fn {x, y} -> x in 0..(width - 1) && y in 0..(height - 1) end)
    |> Enum.uniq()
    |> Enum.sort()
    |> length()
  end

  defp parse_map(map) do
    with rows <- String.split(map),
         height <- length(rows),
         width <- rows |> List.first() |> String.codepoints() |> length() do
      towers =
        for {row, y} <- Enum.with_index(rows),
            {cell, x} <- row |> String.codepoints() |> Enum.with_index(),
            reduce: %{} do
          builder ->
            case cell do
              "." -> builder
              id -> Map.update(builder, id, [{x, y}], &[{x, y} | &1])
            end
        end

      {width, height, towers}
    end
  end

  defp antinodes(map) when is_map(map) do
    map |> Map.values() |> Enum.map(&antinodes/1)
  end

  defp antinodes(towers) when is_list(towers) do
    for a = {ax, ay} <- towers, {bx, by} <- List.delete(towers, a) do
      if ax < bx || (ax == bx && ay < by) do
        [{2 * ax - bx, 2 * ay - by}, {2 * bx - ax, 2 * by - ay}]
      else
        []
      end
    end
  end

  defp harmonic_antinodes(map, width, height) when is_map(map) do
    map |> Map.values() |> Enum.map(&harmonic_antinodes(&1, width, height))
  end

  defp harmonic_antinodes(towers, width, height) when is_list(towers) do
    for a = {ax, ay} <- towers, {bx, by} <- List.delete(towers, a) do
      if ax < bx || (ax == bx && ay < by) do
        {dx, dy} = {ax - bx, ay - by}
        gcd = Integer.gcd(dx, dy)

        {dx, dy} = {div(dx, gcd), div(dy, gcd)}

        Stream.iterate(0, &(&1 + 1))
        |> Stream.take_while(fn multiple ->
          with pos_x <- ax + multiple * dx,
               pos_y <- ay + multiple * dy,
               neg_x <- ax - multiple * dx,
               neg_y <- ay - multiple * dy do
            (pos_x in 0..(width - 1) && pos_y in 0..(height - 1)) ||
              (neg_x in 0..(width - 1) && neg_y in 0..(height - 1))
          end
        end)
        |> Enum.map(fn multiple ->
          with pos_x <- ax + multiple * dx,
               pos_y <- ay + multiple * dy,
               neg_x <- ax - multiple * dx,
               neg_y <- ay - multiple * dy do
            [{pos_x, pos_y}, {neg_x, neg_y}]
          end
        end)
      else
        []
      end
    end
  end
end

sample =
  """
  ............
  ........0...
  .....0......
  .......0....
  ....0.......
  ......A.....
  ............
  ............
  ........A...
  .........A..
  ............
  ............
  """
  |> String.trim()

data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day08.part_one(data))
IO.inspect(Day08.part_two(data))
