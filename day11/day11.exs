defmodule Day11 do
  use Agent

  def part_both(data, steps) do
    start_agent()
    data |> String.split() |> run_steps(steps) |> Enum.sum()
  end

  def start_agent(), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  def run_steps(stones, steps) do
    Enum.map(stones, &expand_stone_length(&1, steps))
  end

  defp expand_stone_length(_, 0), do: 1

  defp expand_stone_length(stone, steps) do
    if cached_len = Agent.get(__MODULE__, &Map.get(&1, {stone, steps})) do
      cached_len
    else
      Enum.map(step_stone(stone), &expand_stone_length(&1, steps - 1))
      |> Enum.sum()
      |> tap(fn len ->
        Agent.update(__MODULE__, &Map.put(&1, {stone, steps}, len))
      end)
    end
  end

  defp step_stone("0"), do: ["1"]

  defp step_stone(stone) do
    case rem(String.length(stone), 2) do
      0 ->
        String.split_at(stone, div(String.length(stone), 2))
        |> Tuple.to_list()
        |> Enum.map(&(&1 |> String.to_integer() |> Integer.to_string()))

      1 ->
        ["#{String.to_integer(stone) * 2024}"]
    end
  end
end

sample = "125 17"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))
IO.inspect(Day11.part_both(data, 25))
IO.inspect(Day11.part_both(data, 75))
