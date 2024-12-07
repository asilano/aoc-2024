import Bitwise

defmodule Day07 do
  def part_one(data) do
    data
    |> String.split("\n")
    |> Enum.map(&satisfiable_line/1)
    |> Enum.sum()
  end

  def part_two(data) do
    data
    |> String.split("\n")
    |> Task.async_stream(&satisfiable_line_concats/1)
    |> Enum.map(fn {:ok, result} -> result end)
    |> Enum.sum()
  end

  defp satisfiable_line(line) do
    with [target, opands] <- String.split(line, ": "),
         target <- String.to_integer(target),
         opands <- String.split(opands) |> Enum.map(&String.to_integer/1) do
      if Enum.any?(0..(2 ** (length(opands) - 1) - 1), fn binary ->
           satisfied?(target, opands, binary)
         end),
         do: target,
         else: 0
    end
  end

  defp satisfied?(target, opands, binary_coded_operators) do
    opands
    |> Enum.drop(1)
    |> Enum.with_index()
    |> Enum.reduce(List.first(opands), fn {val, index}, sum ->
      case binary_coded_operators &&& 2 ** index do
        0 -> sum + val
        _ -> sum * val
      end
    end) == target
  end

  defp satisfiable_line_concats(line) do
    with [target, opands] <- String.split(line, ": "),
         target <- String.to_integer(target),
         opands <- String.split(opands) |> Enum.map(&String.to_integer/1) do
      if Enum.any?(0..(3 ** (length(opands) - 1) - 1), fn ternary ->
           satisfied_concats?(target, opands, ternary)
         end),
         do: target,
         else: 0
    end
  end

  defp satisfied_concats?(target, opands, ternary_coded_operators) do
    opands
    |> Enum.drop(1)
    |> Enum.with_index()
    |> Enum.reduce(List.first(opands), fn {val, index}, sum ->
      case div(ternary_coded_operators, 3 ** index) |> rem(3) do
        0 -> sum + val
        1 -> sum * val
        2 -> String.to_integer("#{sum}#{val}")
      end
    end) == target
  end
end

sample = "190: 10 19
3267: 81 40 27
83: 17 5
156: 15 6
7290: 6 8 6 15
161011: 16 10 13
192: 17 8 14
21037: 9 7 18 13
292: 11 6 16 20"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day07.part_one(data))
IO.inspect(Day07.part_two(data))
