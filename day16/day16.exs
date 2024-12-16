defmodule AStar do
  def run(start, finish, adjacency_fn, step_cost_fn, heuristic_fn, display_fn) do
    step([start], %{start => 0}, finish, adjacency_fn, step_cost_fn, heuristic_fn, display_fn)
  end

  defp step(search_front, dist_map, finish, adjacency_fn, step_cost_fn, heuristic_fn, display_fn) do
    expand_from = search_front |> Enum.min_by(&(Map.get(dist_map, &1) + heuristic_fn.(&1)))

    case expand_from do
      {^finish, _} ->
        Map.get(dist_map, expand_from)

      _ ->
        adjacent_states =
          adjacency_fn.(expand_from)
          |> Enum.filter(fn adjacent ->
            !Map.has_key?(dist_map, adjacent) ||
              Map.get(dist_map, expand_from) + step_cost_fn.(expand_from, adjacent) < Map.get(dist_map, adjacent)
          end)

        dist_map =
          Enum.reduce(adjacent_states, dist_map, fn adjacent, dist_map ->
            new_cost = Map.get(dist_map, expand_from) + step_cost_fn.(expand_from, adjacent)
            Map.put(dist_map, adjacent, new_cost)
          end)

        search_front = List.delete(search_front, expand_from) ++ adjacent_states
        step(search_front, dist_map, finish, adjacency_fn, step_cost_fn, heuristic_fn, display_fn)
    end
  end
end

defmodule Dijkstra do
  def run(start, infinite_map, adjacency_fn, step_cost_fn) do
    step(
      start,
      %{infinite_map | start => 0},
      infinite_map |> Map.delete(start) |> Map.keys() |> MapSet.new(),
      adjacency_fn,
      step_cost_fn
    )
  end

  def step(expand_from, dist_map, unvisited, adjacency_fn, step_cost_fn) do
    if MapSet.size(unvisited) == 0 do
      dist_map
    else
      adjacent_states = adjacency_fn.(expand_from) |> Enum.filter(&MapSet.member?(unvisited, &1))

      dist_map =
        Enum.reduce(adjacent_states, dist_map, fn adjacent, dist_map ->
          new_cost = Map.get(dist_map, expand_from) + step_cost_fn.(expand_from, adjacent)

          if (old_cost = Map.get(dist_map, adjacent)) == :infinity or new_cost < old_cost do
            Map.put(dist_map, adjacent, new_cost)
          else
            dist_map
          end
        end)

      next =
        dist_map
        |> Enum.filter(fn {loc, dist} -> dist != :infinity and MapSet.member?(unvisited, loc) end)
        |> Enum.min_by(fn {_, dist} -> dist end)
        |> elem(0)

      unvisited = MapSet.delete(unvisited, next)
      step(next, dist_map, unvisited, adjacency_fn, step_cost_fn)
    end
  end
end

defmodule Day16 do
  def part_one(data) do
    with {floor_plan, start, finish} <- parse_map(data) do
      {AStar.run(
         {start, :e},
         finish,
         &adjacent(&1, floor_plan),
         &step_cost/2,
         &heuristic(&1, finish),
         &display_maze(&1, floor_plan)
       ), floor_plan, start, finish}
    end
  end

  def part_two(data) do
    {best, floor_plan, start, finish} = part_one(data)
    # IO.puts(IO.ANSI.clear())
    # display_maze({start, :e}, floor_plan)

    infinite_map =
      floor_plan
      |> Enum.filter(fn {_, type} -> type == :floor end)
      |> Enum.reduce(%{}, fn {loc, _}, map ->
        map
        |> Map.put({loc, :n}, :infinity)
        |> Map.put({loc, :e}, :infinity)
        |> Map.put({loc, :s}, :infinity)
        |> Map.put({loc, :w}, :infinity)
      end)

    dijk_from_start = Dijkstra.run({start, :e}, infinite_map, &adjacent(&1, floor_plan), &step_cost/2)
    dijk_from_f_north = Dijkstra.run({finish, :s}, infinite_map, &adjacent(&1, floor_plan), &step_cost/2)
    dijk_from_f_east = Dijkstra.run({finish, :w}, infinite_map, &adjacent(&1, floor_plan), &step_cost/2)

    dijk_from_finish =
      Map.merge(dijk_from_f_east, dijk_from_f_north, fn _, d1, d2 -> min(d1, d2) end)
      |> Enum.map(fn {{loc, dir}, dist} ->
        case dir do
          :n -> {{loc, :s}, dist}
          :e -> {{loc, :w}, dist}
          :s -> {{loc, :n}, dist}
          :w -> {{loc, :e}, dist}
        end
      end)
      |> Enum.into(%{})

    dijk_combined = Map.merge(dijk_from_start, dijk_from_finish, fn _, ds, df -> ds + df end)

    dijk_combined
    |> Enum.filter(fn {_, dist} -> dist == best end)
    |> Enum.map(fn {{loc, _}, _} -> loc end)
    |> Enum.uniq()
    # |> tap(fn list ->
    #   output =
    #     Enum.map(list, fn {x, y} ->
    #       IO.ANSI.blue() <> IO.ANSI.cursor(y + 1, x + 1) <> "O" <> IO.ANSI.reset()
    #     end)
    #     |> Enum.join()

    #   IO.puts(
    #     output <>
    #       IO.ANSI.reset() <> IO.ANSI.cursor(Enum.max(Map.keys(floor_plan) |> Enum.map(fn {_, y} -> y end)) + 1, 0)
    #   )
    # end)
    |> Enum.count()
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

  defp adjacent(location = {{x, y}, dir}, floor_plan) do
    forward =
      if Map.get(floor_plan, in_front_of(location)) == :floor do
        [{in_front_of(location), dir}]
      else
        []
      end

    turns =
      case dir do
        :n -> [{{x, y}, :e}, {{x, y}, :w}]
        :e -> [{{x, y}, :n}, {{x, y}, :s}]
        :s -> [{{x, y}, :e}, {{x, y}, :w}]
        :w -> [{{x, y}, :n}, {{x, y}, :s}]
      end

    forward ++ turns
  end

  defp in_front_of({{x, y}, dir}) do
    case dir do
      :n -> {x, y - 1}
      :e -> {x + 1, y}
      :s -> {x, y + 1}
      :w -> {x - 1, y}
    end
  end

  defp step_cost({_, fd}, {_, td}) do
    if fd == td, do: 1, else: 1000
  end

  defp heuristic({{x, y}, _}, {x, y}), do: 0

  defp heuristic({{x, y}, dir}, {finish_x, finish_y}) do
    distance = abs(y - finish_y) + abs(x - finish_x)

    turns =
      cond do
        x == finish_x and dir in [:e, :w] -> 1
        x == finish_x and y < finish_y and dir == :n -> 2
        x == finish_x and y < finish_y and dir == :s -> 0
        x == finish_x and y > finish_y and dir == :n -> 0
        x == finish_x and y > finish_y and dir == :s -> 2
        y == finish_y and dir in [:n, :s] -> 1
        y == finish_y and x < finish_x and dir == :w -> 2
        y == finish_y and x < finish_x and dir == :e -> 0
        y == finish_y and x > finish_x and dir == :w -> 0
        y == finish_y and x > finish_x and dir == :e -> 2
        true -> 1
      end

    distance + 1000 * turns
  end

  defp display_maze({{x, y}, dir}, floor_plan) do
    output =
      Enum.map(floor_plan, fn {{x, y}, cell} ->
        IO.ANSI.cursor(y + 1, x + 1) <>
          case cell do
            :wall -> IO.ANSI.red() <> "#"
            :floor -> IO.ANSI.white() <> "."
          end
      end)
      |> Enum.join()

    reindeer =
      case dir do
        :n -> "^"
        :e -> ">"
        :s -> "v"
        :w -> "<"
      end

    IO.puts(
      output <>
        IO.ANSI.cursor(y + 1, x + 1) <>
        IO.ANSI.green() <>
        reindeer <>
        IO.ANSI.reset() <> IO.ANSI.cursor(Enum.max(Map.keys(floor_plan) |> Enum.map(fn {_, y} -> y end)) + 1, 0)
    )
  end
end

sample =
  """
  ###############
  #.......#....E#
  #.#.###.#.###.#
  #.....#.#...#.#
  #.###.#####.#.#
  #.#.#.......#.#
  #.#.#####.###.#
  #...........#.#
  ###.#.#####.#.#
  #...#.....#.#.#
  #.#.#.###.#.#.#
  #.....#...#.#.#
  #.###.#.#.#.#.#
  #S..#.....#...#
  ###############
  """
  |> String.trim()

data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day16.part_one(data) |> elem(0))
IO.inspect(Day16.part_two(data))
