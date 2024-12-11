defmodule Day11 do
  def part_one(data) do
    data |> String.split() |> run_steps(25) |> length()
  end

  defp run_steps(stones, 0), do: stones

  defp run_steps(stones, steps) do
    run_steps(Enum.flat_map(stones, &step_stone/1), steps - 1)
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
IO.inspect(Day11.part_one(data))
