defmodule Day05 do
  def part_one(data) do
    with [rules, updates] <- String.split(data, "\n\n"),
         {succession, _} <- parse_rules(rules) do
      updates
      |> String.split()
      |> Enum.map(&(String.split(&1, ",") |> Enum.reverse()))
      |> Enum.filter(&valid_update?(&1, %{}, succession))
      |> Enum.map(&Enum.at(&1, div(length(&1), 2)))
      |> Enum.map(&String.to_integer/1)
      |> Enum.sum()
    end
  end

  def part_two(data) do
    with [rules, updates] <- String.split(data, "\n\n"),
         {succession, predecessors} <- parse_rules(rules),
         updates <- updates |> String.split() |> Enum.map(&String.split(&1, ",")),
         invalids <- Enum.reject(updates, &valid_update?(Enum.reverse(&1), %{}, succession)) do
      invalids
      |> Enum.map(&make_valid(&1, predecessors))
      |> Enum.map(&Enum.at(&1, div(length(&1), 2)))
      |> Enum.map(&String.to_integer/1)
      |> Enum.sum()
    end
  end

  defp parse_rules(rules) do
    rules
    |> String.split()
    |> Enum.map(fn rule -> rule |> String.split("|") end)
    |> Enum.reduce({%{}, %{}}, fn [earlier, later], {succession, predecessors} ->
      {Map.update(succession, earlier, [later], &[later | &1]),
       Map.update(predecessors, later, [earlier], &[earlier | &1])}
    end)
  end

  defp valid_update?(update, illegal, succession)

  defp valid_update?([], _, _), do: true
  defp valid_update?([a | _], illegal, _) when is_map_key(illegal, a), do: false

  defp valid_update?([a | rest], illegal, succession) do
    updated_illegal = Enum.reduce(Map.get(succession, a, []), illegal, &Map.put(&2, &1, true))
    valid_update?(rest, updated_illegal, succession)
  end

  defp make_valid(pages, predecessors) do
    Enum.reduce(pages, %{}, fn page, prereq_tree ->
      Map.put(
        prereq_tree,
        page,
        predecessors |> Map.get(page, []) |> Enum.filter(&Enum.member?(pages, &1))
      )
    end)
    |> build_ordering([])
  end

  defp build_ordering(prereq_map, builder) when map_size(prereq_map) == 0, do: builder

  defp build_ordering(prereq_map, builder) do
    next_step =
      prereq_map
      |> Map.filter(fn {_, prereqs} -> prereqs == [] end)
      |> Map.keys()
      |> Enum.sort()
      |> List.first()

    prereq_map =
      Enum.map(prereq_map, fn {follower, prereqs} ->
        {follower, List.delete(prereqs, next_step)}
      end)
      |> Enum.into(%{})
      |> Map.delete(next_step)

    build_ordering(prereq_map, [next_step | builder])
  end
end

sample = "47|53
97|13
97|61
97|47
75|29
61|13
75|53
29|13
97|29
53|29
61|53
97|53
61|29
47|13
75|47
97|75
47|61
75|61
47|29
75|13
53|13

75,47,61,53,29
97,61,53,29,13
75,29,13
75,97,47,61,53
61,13,29
97,13,75,29,47"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day05.part_one(data))
IO.inspect(Day05.part_two(data))
