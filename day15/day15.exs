defmodule Day15 do
  def part_one(data) do
    IO.puts(IO.ANSI.clear())

    with [map, instructions] <- String.split(data, "\n\n"),
         {floor_plan, robot} <- parse_warehouse(map),
         instructions <- String.codepoints(instructions) |> Enum.reject(&(&1 == "\n")) do
      draw_warehouse(floor_plan)
      Enum.reduce(instructions, {floor_plan, robot}, &run_step/2) |> then(fn {floor_plan, _} -> gps_sum(floor_plan) end)
    end
  end

  def part_two(data) do
    IO.puts(IO.ANSI.clear())

    with [map, instructions] <- String.split(data, "\n\n"),
         {floor_plan, robot} <- parse_warehouse(map),
         {floor_plan, robot} <- expand_warehouse(floor_plan, robot),
         instructions <- String.codepoints(instructions) |> Enum.reject(&(&1 == "\n")) do
      draw_warehouse(floor_plan)

      Enum.reduce(instructions, {floor_plan, robot}, &run_step/2) |> then(fn {floor_plan, _} -> gps_sum(floor_plan) end)
    end
  end

  defp parse_warehouse(map) do
    for {line, y} <- map |> String.split() |> Enum.with_index(),
        {cell, x} <- line |> String.codepoints() |> Enum.with_index(),
        reduce: {%{}, nil} do
      {floor_plan, robot} ->
        case cell do
          "#" -> {Map.put(floor_plan, {x, y}, :wall), robot}
          "." -> {Map.put(floor_plan, {x, y}, :floor), robot}
          "O" -> {Map.put(floor_plan, {x, y}, :box), robot}
          "@" -> {Map.put(floor_plan, {x, y}, :robot), {x, y}}
        end
    end
  end

  defp expand_warehouse(floor_plan, {rx, ry}) do
    new_plan =
      floor_plan
      |> Enum.reduce(%{}, fn {{x, y}, type}, new_plan ->
        case type do
          :wall -> new_plan |> Map.put({2 * x, y}, :wall) |> Map.put({2 * x + 1, y}, :wall)
          :floor -> new_plan |> Map.put({2 * x, y}, :floor) |> Map.put({2 * x + 1, y}, :floor)
          :box -> new_plan |> Map.put({2 * x, y}, :left) |> Map.put({2 * x + 1, y}, :right)
          :robot -> new_plan |> Map.put({2 * x, y}, :robot) |> Map.put({2 * x + 1, y}, :floor)
        end
      end)

    {new_plan, {2 * rx, ry}}
  end

  defp draw_warehouse(floor_plan) do
    output =
      Enum.map(floor_plan, fn {{x, y}, cell} ->
        IO.ANSI.cursor(y + 1, x + 1) <>
          case cell do
            :wall -> IO.ANSI.red() <> "#"
            :floor -> IO.ANSI.white() <> "."
            :box -> IO.ANSI.green() <> "O"
            :left -> IO.ANSI.green() <> "["
            :right -> IO.ANSI.green() <> "]"
            :robot -> IO.ANSI.blue() <> "@"
          end
      end)
      |> Enum.join()

    IO.puts(
      output <> IO.ANSI.reset() <> IO.ANSI.cursor(Enum.max(Map.keys(floor_plan) |> Enum.map(fn {_, y} -> y end)) + 1, 0)
    )
  end

  defp run_step(step, {floor_plan, robot}) do
    change_fn =
      case step do
        "<" -> fn {x, y} -> {x - 1, y} end
        "^" -> fn {x, y} -> {x, y - 1} end
        ">" -> fn {x, y} -> {x + 1, y} end
        "v" -> fn {x, y} -> {x, y + 1} end
      end

    push_list =
      try do
        build_push(:robot, floor_plan, robot, change_fn, [])
      catch
        :hit_wall -> []
      end

    sort_fn =
      case step do
        "<" -> fn {x, _} -> x end
        "^" -> fn {_, y} -> y end
        ">" -> fn {x, _} -> -x end
        "v" -> fn {_, y} -> -y end
      end

    push_list = Enum.sort_by(push_list, sort_fn)

    floor_plan =
      push_list
      |> Enum.uniq()
      |> Enum.reduce(floor_plan, fn from, next_floor_plan ->
        if Map.get(floor_plan, from) == :floor do
          next_floor_plan
        else
          next_floor_plan
          |> Map.put(change_fn.(from), Map.get(floor_plan, from))
          |> Map.put(from, :floor)
        end
      end)

    robot =
      if !Enum.empty?(push_list) do
        change_fn.(robot)
      else
        robot
      end

    # Process.sleep(10)
    # draw_warehouse(floor_plan)
    {floor_plan, robot}
  end

  defp build_push(cell, floor_plan, location, change, builder)
  defp build_push(:floor, floor_plan, _, _, builder), do: builder
  defp build_push(:wall, floor_plan, _, _, _), do: throw(:hit_wall)

  defp build_push(object, floor_plan, {x, y}, change, builder) when object in [:box, :robot] do
    with {nx, ny} <- change.({x, y}), cell <- Map.get(floor_plan, {nx, ny}) do
      build_push(cell, floor_plan, {nx, ny}, change, [{x, y} | builder])
    end
  end

  defp build_push(:left, floor_plan, {x, y}, change, builder) do
    if {x, y} in builder do
      builder
    else
      with {nx, ny} <- change.({x, y}), cell <- Map.get(floor_plan, {nx, ny}) do
        builder = build_push(cell, floor_plan, {nx, ny}, change, [{x, y} | builder])
        builder = build_push(:right, floor_plan, {x + 1, y}, change, builder)
        [{x + 1, y} | builder]
      end
    end
  end

  defp build_push(:right, floor_plan, {x, y}, change, builder) do
    if {x, y} in builder do
      builder
    else
      with {nx, ny} <- change.({x, y}), cell <- Map.get(floor_plan, {nx, ny}) do
        builder = build_push(cell, floor_plan, {nx, ny}, change, [{x, y} | builder])
        builder = build_push(:left, floor_plan, {x - 1, y}, change, builder)
        [{x - 1, y} | builder]
      end
    end
  end

  defp gps_sum(floor_plan) do
    floor_plan
    |> Enum.filter(fn {_, type} -> type in [:box, :left] end)
    |> Enum.map(fn {{x, y}, _} -> 100 * y + x end)
    |> Enum.sum()
  end
end

sample = "##########
#..O..O.O#
#......O.#
#.OO..O.O#
#..O@..O.#
#O#..O...#
#O..O..O.#
#.OO.O.OO#
#....O...#
##########

<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day15.part_one(data))
IO.gets("")
IO.inspect(Day15.part_two(data))
