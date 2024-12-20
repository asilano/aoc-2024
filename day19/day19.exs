defmodule Day19 do
  use Agent

  def part_both(data) do
    start_agent()

    [towels_part, patterns_part] = String.split(data, "\n\n")
    towels = String.split(towels_part, ", ")
    patterns = String.split(patterns_part)

    ways_to_make = Enum.map(patterns, &ways_to_make_pattern(&1, "", 1, towels))
    valid_patterns = Enum.filter(ways_to_make, &(&1 != 0))
    IO.puts("Valid patterns: #{length(valid_patterns)}")
    IO.puts("Total arrangements: #{Enum.sum(valid_patterns)}")
  end

  defp start_agent() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  defp store_fragment(fragment, possible), do: Agent.update(__MODULE__, &Map.put(&1, fragment, possible))

  defp check_fragment(fragment), do: Agent.get(__MODULE__, &Map.get(&1, fragment))

  defp ways_to_make_pattern("", _, _, _), do: 1

  defp ways_to_make_pattern(pattern, prefix, ways, towels) do
    if (result = check_fragment(pattern)) != nil do
      result
    else
      ways_onward =
        Enum.filter(towels, &String.starts_with?(pattern, &1))
        |> Enum.map(fn towel ->
          ways_to_make_pattern(String.replace_prefix(pattern, towel, ""), prefix <> towel, ways, towels)
        end)
        |> Enum.sum()

      (ways_onward * ways)
      |> tap(fn result ->
        store_fragment(pattern, result)
      end)
    end
  end
end

sample = "r, wr, b, g, bwu, rb, gb, br

brwrr
bggr
gbbr
rrbgbr
ubwu
bwurrg
brgr
bbrgwb"

data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day19.part_both(data))
