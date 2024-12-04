defmodule Day04 do
  def part_one(data) do
    [
      &lines/1,
      &lines_reverse/1,
      &columns/1,
      &columns_reverse/1,
      &sw_ne/1,
      &sw_ne_reverse/1,
      &nw_se/1,
      &nw_se_reverse/1
    ]
    |> Enum.map(& &1.(data))
    |> Enum.map(fn runs -> Enum.map(runs, &xmas_count/1) |> Enum.sum() end)
    |> Enum.sum()
  end

  def part_two(data) do
    with cell_map <- cell_map(String.split(data)) do
      Enum.count(cell_map, fn
        {{x, y}, "A"} ->
          case {Map.get(cell_map, {x - 1, y - 1}), Map.get(cell_map, {x + 1, y + 1}),
                Map.get(cell_map, {x - 1, y + 1}), Map.get(cell_map, {x + 1, y - 1})} do
            {"M", "S", "M", "S"} -> true
            {"S", "M", "M", "S"} -> true
            {"M", "S", "S", "M"} -> true
            {"S", "M", "S", "M"} -> true
            _ -> false
          end

        {_, _} ->
          false
      end)
    end
  end

  defp lines(data), do: String.split(data)
  defp lines_reverse(data), do: data |> lines() |> Enum.map(&String.reverse/1)

  defp columns(data) do
    with lines <- lines(data),
         line_len <- String.length(List.first(lines)) do
      Enum.map(0..(line_len - 1), fn index ->
        lines
        |> Enum.map(fn line -> line |> String.codepoints() |> Enum.at(index) end)
        |> Enum.join()
      end)
    end
  end

  defp columns_reverse(data), do: data |> columns() |> Enum.map(&String.reverse/1)

  defp sw_ne(data) do
    with lines <- lines(data),
         height <- length(lines),
         width <- String.length(List.first(lines)),
         cell_map <- cell_map(lines) do
      for start_y <- 0..(height - 1) do
        for offset <- 0..start_y do
          Map.get(cell_map, {0 + offset, start_y - offset})
        end
        |> Enum.join()
      end ++
        for start_x <- 1..(width - 1) do
          for offset <- 0..(width - 1 - start_x) do
            Map.get(cell_map, {start_x + offset, height - offset - 1})
          end
          |> Enum.join()
        end
    end
  end

  defp sw_ne_reverse(data), do: data |> sw_ne() |> Enum.map(&String.reverse/1)

  defp nw_se(data) do
    with lines <- lines(data),
         height <- length(lines),
         width <- String.length(List.first(lines)),
         cell_map <- cell_map(lines) do
      for start_y <- (height - 1)..0//-1 do
        for offset <- 0..(height - 1 - start_y) do
          Map.get(cell_map, {0 + offset, start_y + offset})
        end
        |> Enum.join()
      end ++
        for start_x <- 1..(width - 1) do
          for offset <- 0..(width - 1 - start_x) do
            Map.get(cell_map, {start_x + offset, offset})
          end
          |> Enum.join()
        end
    end
  end

  defp nw_se_reverse(data), do: data |> nw_se() |> Enum.map(&String.reverse/1)

  defp cell_map(lines) do
    for {line, y} <- Enum.with_index(lines),
        {char, x} <- Enum.with_index(String.codepoints(line)),
        reduce: %{} do
      map -> Map.put(map, {x, y}, char)
    end
  end

  defp xmas_count(run), do: Regex.scan(~r"XMAS", run) |> length()
end

sample = "MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day04.part_one(data))
IO.inspect(Day04.part_two(data))
