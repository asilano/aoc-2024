defmodule Day03 do
  def part_one(data) do
    Regex.scan(simple_mul_regex(), data)
    |> Enum.map(fn [_, a, b] -> String.to_integer(a) * String.to_integer(b) end)
    |> Enum.sum()
  end

  def part_two(data) do
    Regex.scan(control_flow_regex(), data)
    |> Enum.reduce({0, true}, fn
      [_, a, b], {sum, true} -> {sum + String.to_integer(a) * String.to_integer(b), true}
      ["do()"], {sum, false} -> {sum, true}
      ["don't()"], {sum, true} -> {sum, false}
      _, acc -> acc
    end)
    |> elem(0)
  end

  defp simple_mul_regex(), do: ~r"mul\((\d{1,3}),(\d{1,3})\)"
  defp control_flow_regex(), do: ~r"(?:mul\((\d{1,3}),(\d{1,3})\)|do\(\)|don't\(\))"
end

sample = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day03.part_one(data))
IO.inspect(Day03.part_two(data))
