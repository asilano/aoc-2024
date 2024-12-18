defmodule AStar do
  def run(start, finish, adjacency_fn, step_cost_fn, heuristic_fn, display_fn \\ fn _, _ -> nil end) do
    step([start], %{start => 0}, %{}, finish, adjacency_fn, step_cost_fn, heuristic_fn, display_fn)
  end

  defp step([], _, _, _, _, _, _, _), do: :fail

  defp step(search_front, dist_map, backtrack_map, finish, adjacency_fn, step_cost_fn, heuristic_fn, display_fn) do
    expand_from = search_front |> Enum.min_by(&(Map.get(dist_map, &1) + heuristic_fn.(&1)))

    case expand_from do
      ^finish ->
        {Map.get(dist_map, expand_from), backtrack_map}

      _ ->
        display_fn.(backtrack_map, expand_from)

        adjacent_states =
          adjacency_fn.(expand_from)
          |> Enum.filter(fn adjacent ->
            !Map.has_key?(dist_map, adjacent) ||
              Map.get(dist_map, expand_from) + step_cost_fn.(expand_from, adjacent) < Map.get(dist_map, adjacent)
          end)

        {dist_map, backtrack_map} =
          Enum.reduce(adjacent_states, {dist_map, backtrack_map}, fn adjacent, {dist_map, backtrack_map} ->
            new_cost = Map.get(dist_map, expand_from) + step_cost_fn.(expand_from, adjacent)
            {Map.put(dist_map, adjacent, new_cost), Map.put(backtrack_map, adjacent, expand_from)}
          end)

        search_front = List.delete(search_front, expand_from) ++ adjacent_states
        step(search_front, dist_map, backtrack_map, finish, adjacency_fn, step_cost_fn, heuristic_fn, display_fn)
    end
  end
end

defmodule Day18 do
  def part_one(data, size, time, display \\ false) do
    if display, do: IO.puts(IO.ANSI.clear())

    region = empty_region(size)

    corruption =
      data
      |> String.split()
      |> Enum.map(fn coord_pair -> coord_pair |> String.split(",") |> Enum.map(&String.to_integer/1) end)

    region = fill_region(region, corruption, time)

    display_fn = if display, do: &display(region, &1, &2), else: fn _, _ -> nil end

    with {dist, backtrack} <-
           AStar.run(
             {0, 0},
             {size, size},
             &adjacent(&1, region),
             fn _, _ -> 1 end,
             fn {x, y} -> size - x + size - y end,
             display_fn
           ) do
      if display, do: display(region, backtrack, {size, size})
      dist
    end
  end

  def part_two(data, size, display \\ false) do
    if display, do: IO.puts(IO.ANSI.clear())
    region = empty_region(size)

    corruption =
      data
      |> String.split()
      |> Enum.map(fn coord_pair -> coord_pair |> String.split(",") |> Enum.map(&String.to_integer/1) end)
      |> Enum.map(fn [x, y] -> {x, y} end)

    {_, backtrack_map} =
      AStar.run({0, 0}, {size, size}, &adjacent(&1, region), fn _, _ -> 1 end, fn {x, y} -> size - x + size - y end)

    path = backtrack_trodden(backtrack_map, {size, size}, {0, 0}, [])

    if display do
      display(region, backtrack_map, {size, size})
    end

    Enum.reduce_while(corruption, {region, path}, fn corrupt_cell = {cx, cy}, {region, path} ->
      region = Map.put(region, corrupt_cell, :byte)

      if corrupt_cell not in path do
        {:cont, {region, path}}
      else
        with {_, backtrack_map} <-
               AStar.run({0, 0}, {size, size}, &adjacent(&1, region), fn _, _ -> 1 end, fn {x, y} ->
                 size - x + size - y
               end),
             path <- backtrack_trodden(backtrack_map, {size, size}, {0, 0}, []) do
          if display do
            display(region, backtrack_map, {size, size})
          end

          {:cont, {region, path}}
        else
          :fail ->
            if display do
              Process.sleep(500)

              IO.puts(
                IO.ANSI.cursor(cy + 1, cx + 1) <>
                  IO.ANSI.yellow() <>
                  IO.ANSI.reverse() <>
                  "#" <>
                  IO.ANSI.reset() <> IO.ANSI.cursor(Enum.max(Map.keys(region) |> Enum.map(fn {_, y} -> y end)) + 1, 0)
              )
            end

            {:halt, corrupt_cell}
        end
      end
    end)
  end

  defp empty_region(size) do
    for y <- 0..size, x <- 0..size, into: %{}, do: {{x, y}, :floor}
  end

  defp fill_region(region, corruption, time) do
    corruption
    |> Enum.take(time)
    |> Enum.reduce(region, fn [x, y], map -> Map.put(map, {x, y}, :byte) end)
  end

  defp adjacent({x, y}, region) do
    [
      {x + 1, y},
      {x - 1, y},
      {x, y + 1},
      {x, y - 1}
    ]
    |> Enum.filter(&(Map.get(region, &1) == :floor))
  end

  defp display(region, backtrack_map, search_head) do
    trodden = backtrack_trodden(backtrack_map, search_head, {0, 0}, [])

    output =
      Enum.map(region, fn {{x, y}, cell} ->
        IO.ANSI.cursor(y + 1, x + 1) <>
          cond do
            {x, y} in trodden -> IO.ANSI.white() <> IO.ANSI.bright() <> "O" <> IO.ANSI.reset()
            cell == :byte -> IO.ANSI.red() <> "#"
            cell == :floor -> IO.ANSI.white() <> "."
          end
      end)
      |> Enum.join()

    IO.puts(
      output <>
        IO.ANSI.reset() <> IO.ANSI.cursor(Enum.max(Map.keys(region) |> Enum.map(fn {_, y} -> y end)) + 1, 0)
    )

    Process.sleep(100)
  end

  defp backtrack_trodden(backtrack_map, current, target, builder)

  defp backtrack_trodden(backtrack_map, current, _, builder) when not is_map_key(backtrack_map, current),
    do: [current | builder]

  defp backtrack_trodden(_, target, target, builder), do: [target | builder]

  defp backtrack_trodden(backtrack_map, current, target, builder) do
    backtrack_trodden(backtrack_map, Map.get(backtrack_map, current), target, [current | builder])
  end
end

sample = "5,4
4,2
4,5
3,0
2,1
6,3
2,4
1,5
0,6
3,3
2,6
5,1
1,2
5,5
2,5
6,5
1,4
0,4
6,4
1,1
6,1
1,0
0,5
1,6
2,0"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day18.part_one(sample, 6, 12))
IO.inspect(Day18.part_one(data, 70, 1024))
IO.inspect(Day18.part_two(sample, 6), label: "Sample blocked by")
IO.inspect(Day18.part_two(data, 70), label: "Full problem blocked by")
