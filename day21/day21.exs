defmodule Day21 do
  def part_both(data, middle_robots) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)

    data
    |> String.split()
    |> Enum.map(fn code ->
      numbers = [code]

      steps = steps_with_options(code, numpad_locations())

      best_len =
        steps
        |> Enum.map(fn step_options ->
          step_options
          |> Enum.map(fn option ->
            human_len(option, middle_robots, dirpad_locations(), Agent.get(__MODULE__, & &1))
          end)
          |> Enum.min()
        end)
        |> Enum.sum()

      (code |> String.replace_suffix("A", "") |> String.to_integer()) * best_len
    end)
    |> Enum.sum()
  end

  defp routes(from, to, pad_locations) do
    {fx, fy} = Map.get(pad_locations, from)
    {tx, ty} = Map.get(pad_locations, to)
    {dx, dy} = {tx - fx, ty - fy}

    horiz = horiz_part(dx)
    vert = vert_part(dy)

    # Can't do horiz first if (tx, fy) is the gap
    possibles =
      if Map.values(pad_locations) |> Enum.member?({tx, fy}) do
        [horiz <> vert]
      else
        [false]
      end

    # Can't do vert first if (fx, ty) is the gap
    possibles =
      if Map.values(pad_locations) |> Enum.member?({fx, ty}) do
        [vert <> horiz | possibles]
      else
        [false | possibles]
      end

    Enum.filter(possibles, fn val -> val end) |> Enum.uniq()
  end

  defp human_len(moves, 0, _, _), do: String.length(moves)
  defp human_len(moves, steps, _, cache) when is_map_key(cache, {moves, steps}), do: Map.get(cache, {moves, steps})

  defp human_len(moves, steps, pad, _) do
    next_steps = steps_with_options(moves, pad)

    next_steps
    |> Enum.map(fn step_options ->
      step_options
      |> Enum.map(fn option ->
        human_len(option, steps - 1, pad, Agent.get(__MODULE__, & &1))
      end)
      |> Enum.min()
    end)
    |> Enum.sum()
    |> tap(&Agent.update(__MODULE__, fn cache -> Map.put(cache, {moves, steps}, &1) end))
  end

  defp moves(buttons_options, pad) do
    Enum.flat_map(buttons_options, fn buttons ->
      ["A" | String.codepoints(buttons)]
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.reduce([""], fn [from, to], routes ->
        Enum.flat_map(routes, fn route ->
          routes(from, to, pad) |> Enum.map(&(route <> &1 <> "A"))
        end)
      end)
    end)
  end

  defp steps_with_options(buttons, pad) do
    ["A" | String.codepoints(buttons)]
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce([], fn [from, to], builder ->
      [routes(from, to, pad) |> Enum.map(&(&1 <> "A")) | builder]
    end)
    |> Enum.reverse()
  end

  defp numpad_locations() do
    %{
      "7" => {0, 0},
      "8" => {1, 0},
      "9" => {2, 0},
      "4" => {0, 1},
      "5" => {1, 1},
      "6" => {2, 1},
      "1" => {0, 2},
      "2" => {1, 2},
      "3" => {2, 2},
      "0" => {1, 3},
      "A" => {2, 3}
    }
  end

  defp dirpad_locations() do
    %{
      "^" => {1, 0},
      "A" => {2, 0},
      "<" => {0, 1},
      "v" => {1, 1},
      ">" => {2, 1}
    }
  end

  defp horiz_part(dx) when dx == 0, do: ""
  defp horiz_part(dx) when dx > 0, do: String.duplicate(">", dx)
  defp horiz_part(dx) when dx < 0, do: String.duplicate("<", abs(dx))
  defp vert_part(dy) when dy == 0, do: ""
  defp vert_part(dy) when dy > 0, do: String.duplicate("v", dy)
  defp vert_part(dy) when dy < 0, do: String.duplicate("^", abs(dy))
end

sample = "029A
980A
179A
456A
379A"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))
IO.inspect(Day21.part_both(data, 2))
IO.inspect(Day21.part_both(data, 25))
