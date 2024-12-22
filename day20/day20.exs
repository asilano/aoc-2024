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

defmodule Day20 do
  def part_one(data, cheat_dist) do
    {region, start, finish = {fx, fy}} = parse_map(data)

    {min_dist, backtrack_map} =
      AStar.run(start, finish, &adjacent(&1, region), fn _, _ -> 1 end, fn {x, y} -> fx - x + fy - y end)

    trodden = backtrack_trodden(backtrack_map, finish, start, []) |> Enum.with_index() |> Enum.into(%{})

    cheat_walls =
      for depart = {{ax, ay}, _} <- trodden,
          emerge <-
            Enum.filter(trodden, fn {{bx, by}, _} ->
              abs(ax - bx) + abs(ay - by) <= cheat_dist
            end) do
        {depart, emerge}
      end
      |> Enum.map(fn {{{ax, ay}, step_a}, {{bx, by}, step_b}} ->
        step_a - step_b - (abs(ax - bx) + abs(ay - by))
      end)
      |> Enum.count(&(&1 >= 100))
  end

  defp parse_map(data) do
    for {line, y} <- data |> String.split() |> Enum.with_index(),
        {cell, x} <- line |> String.codepoints() |> Enum.with_index(),
        reduce: {%{}, nil, nil} do
      {floor_plan, start, finish} ->
        case cell do
          "#" -> {Map.put(floor_plan, {x, y}, :wall), start, finish}
          "." -> {Map.put(floor_plan, {x, y}, :floor), start, finish}
          "S" -> {Map.put(floor_plan, {x, y}, :floor), {x, y}, finish}
          "E" -> {Map.put(floor_plan, {x, y}, :floor), start, {x, y}}
        end
    end
  end

  defp adjacent({x, y}, region) do
    [
      {{x + 1, y}, :e},
      {{x - 1, y}, :w},
      {{x, y + 1}, :s},
      {{x, y - 1}, :n}
    ]
    |> Enum.filter(fn {cell, travel_dir} ->
      Map.get(region, cell) in [:floor, travel_dir]
    end)
    |> Enum.map(&elem(&1, 0))
  end

  defp backtrack_trodden(backtrack_map, current, target, builder)

  defp backtrack_trodden(backtrack_map, current, _, builder) when not is_map_key(backtrack_map, current),
    do: [current | builder]

  defp backtrack_trodden(_, target, target, builder), do: [target | builder]

  defp backtrack_trodden(backtrack_map, current, target, builder) do
    backtrack_trodden(backtrack_map, Map.get(backtrack_map, current), target, [current | builder])
  end
end

sample =
  """
  ###############
  #...#...#.....#
  #.#.#.#.#.###.#
  #S#...#.#.#...#
  #######.#.#.###
  #######.#.#...#
  #######.#.###.#
  ###..E#...#...#
  ###.#######.###
  #...###...#...#
  #.#####.#.###.#
  #.#...#.#.#...#
  #.#.#.#.#.#.###
  #...#...#...###
  ###############
  """
  |> String.trim()

data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day20.part_one(data, 2))
IO.inspect(Day20.part_one(data, 20))
