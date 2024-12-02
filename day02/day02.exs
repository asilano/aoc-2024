defmodule Day02 do
  def part_one(data) do
    data
    |> String.split("\n")
    |> Enum.map(fn line -> line |> String.split() |> Enum.map(&String.to_integer/1) end)
    |> Enum.count(&safe/1)
  end

  def part_two(data) do
    data
    |> String.split("\n")
    |> Enum.map(fn line -> line |> String.split() |> Enum.map(&String.to_integer/1) end)
    |> Enum.count(fn list ->
      Enum.any?(0..(length(list) - 1), fn ix ->
        list |> List.delete_at(ix) |> safe()
      end)
    end)
  end

  defp safe(list) do
    safe(list, nil)
  end

  defp safe([a, b | _], _) when abs(a - b) > 3 or a == b, do: false
  defp safe([_], _), do: true

  defp safe([a, b | rest], nil) do
    safe([b | rest], if(a - b > 0, do: :decreasing, else: :increasing))
  end

  defp safe([a, b | rest], :decreasing) when a > b, do: safe([b | rest], :decreasing)
  defp safe([a, b | rest], :increasing) when a < b, do: safe([b | rest], :increasing)
  defp safe(_, _), do: false
end

sample = "7 6 4 2 1
1 2 7 8 9
9 7 6 2 1
1 3 2 4 5
8 6 4 4 1
1 3 6 7 9"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day02.part_one(data))
IO.inspect(Day02.part_two(data))
