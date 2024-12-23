defmodule Day23 do
  def part_one(data) do
    connections = connections(data)

    Map.keys(connections)
    |> Enum.filter(&String.starts_with?(&1, "t"))
    |> Enum.flat_map(fn t_computer ->
      for a <- Map.get(connections, t_computer),
          b <- Map.get(connections, t_computer),
          a != b,
          MapSet.member?(Map.get(connections, a), b) do
        {t_computer, a, b}
      end
    end)
    |> Enum.uniq_by(fn {t, a, b} -> Enum.sort([t, a, b]) end)
    |> Enum.count()
  end

  def part_two(data) do
    connections = connections(data)

    Map.keys(connections)
    |> Enum.reduce([], fn a, cliques ->
      Enum.reduce(Map.get(connections, a), cliques, fn b, cliques ->
        add_to_ix =
          Enum.find_index(cliques, fn clique ->
            Enum.member?(clique, a) and
              Enum.all?(clique, &MapSet.member?(Map.get(connections, b), &1))
          end)

        if add_to_ix do
          List.update_at(cliques, add_to_ix, fn clique -> [b | clique] end)
        else
          [[a, b] | cliques]
        end
      end)
    end)
    |> Enum.map(&Enum.sort/1)
    |> Enum.uniq()
    |> Enum.max_by(&length/1)
    |> Enum.join(",")
  end

  defp connections(data) do
    data
    |> String.split()
    |> Enum.map(&String.split(&1, "-"))
    |> Enum.reduce(%{}, fn [a, b], connect_map ->
      connect_map
      |> Map.update(a, MapSet.new([b]), &MapSet.put(&1, b))
      |> Map.update(b, MapSet.new([a]), &MapSet.put(&1, a))
    end)
  end
end

sample = "kh-tc
qp-kh
de-cg
ka-co
yn-aq
qp-ub
cg-tb
vc-aq
tb-ka
wh-tc
yn-cg
kh-ub
ta-co
de-co
tc-td
tb-wq
wh-td
ta-ka
td-qp
aq-cg
wq-ub
ub-vc
de-ta
wq-aq
wq-vc
wh-yn
ka-de
kh-ta
co-tc
wh-qp
tb-vc
td-yn"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day23.part_one(data))
IO.inspect(Day23.part_two(data))
