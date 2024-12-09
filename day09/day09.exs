defmodule Day09 do
  def part_one(data) do
    data |> String.codepoints() |> Enum.map(&String.to_integer/1) |> defrag()
  end

  def part_two(data) do
    {files, gaps} =
      with {files, gaps} <-
             data
             |> String.codepoints()
             |> Enum.map(&String.to_integer/1)
             |> Enum.with_index()
             |> Enum.split_with(fn {_, ix} -> rem(ix, 2) == 0 end) do
        {Enum.map(files, &elem(&1, 0)), Enum.map(gaps, &elem(&1, 0))}
      end

    defrag_files(files, gaps)
  end

  defp defrag(sizes) do
    with sizes_reverse <- Enum.reverse(sizes),
         max_file_id <- div(length(sizes), 2),
         total_file_size <- sizes |> Enum.take_every(2) |> Enum.sum() do
      defrag_checksum(sizes, sizes_reverse, :file, 0, max_file_id, 0, total_file_size, 0)
    end
  end

  defp defrag_checksum(
         sizes,
         sizes_reverse,
         mode,
         fwd_file_id,
         rev_file_id,
         block_id,
         total_file_size,
         checksum
       )

  defp defrag_checksum(_, _, _, _, _, total_file_size, total_file_size, checksum), do: checksum

  defp defrag_checksum(
         [0 | rest],
         sizes_reverse,
         :file,
         fwd_file_id,
         rev_file_id,
         block_id,
         total_file_size,
         checksum
       ) do
    defrag_checksum(
      rest,
      sizes_reverse,
      :gap,
      fwd_file_id + 1,
      rev_file_id,
      block_id,
      total_file_size,
      checksum
    )
  end

  defp defrag_checksum(
         [file_size | rest],
         sizes_reverse,
         :file,
         fwd_file_id,
         rev_file_id,
         block_id,
         total_file_size,
         checksum
       ) do
    # IO.write(fwd_file_id)

    defrag_checksum(
      [file_size - 1 | rest],
      sizes_reverse,
      :file,
      fwd_file_id,
      rev_file_id,
      block_id + 1,
      total_file_size,
      checksum + block_id * fwd_file_id
    )
  end

  defp defrag_checksum(
         [gap_size | rest],
         [0, _ | rest_reverse],
         :gap,
         fwd_file_id,
         rev_file_id,
         block_id,
         total_file_size,
         checksum
       ) do
    defrag_checksum(
      [gap_size | rest],
      rest_reverse,
      :gap,
      fwd_file_id,
      rev_file_id - 1,
      block_id,
      total_file_size,
      checksum
    )
  end

  defp defrag_checksum(
         [0 | rest],
         sizes_reverse,
         :gap,
         fwd_file_id,
         rev_file_id,
         block_id,
         total_file_size,
         checksum
       ) do
    defrag_checksum(
      rest,
      sizes_reverse,
      :file,
      fwd_file_id,
      rev_file_id,
      block_id,
      total_file_size,
      checksum
    )
  end

  defp defrag_checksum(
         [gap_size | rest],
         [file_size | rest_reverse],
         :gap,
         fwd_file_id,
         rev_file_id,
         block_id,
         total_file_size,
         checksum
       ) do
    # IO.write(rev_file_id)

    defrag_checksum(
      [gap_size - 1 | rest],
      [file_size - 1 | rest_reverse],
      :gap,
      fwd_file_id,
      rev_file_id,
      block_id + 1,
      total_file_size,
      checksum + block_id * rev_file_id
    )
  end

  defp defrag_files(files, gaps) do
    with {undefrag_map, empty_gap_map, _} <- undefrag_map(files, gaps),
         gap_map <- gap_map(Enum.reverse(files), length(files) - 1, gaps, %{}) do
      {file_map, _} = Enum.reduce(gap_map, {undefrag_map, empty_gap_map}, &fill_gap/2)

      file_map
      |> Enum.map(fn {file_id, {start, size}} ->
        start..(start + size - 1) |> Enum.map(&(&1 * file_id)) |> Enum.sum()
      end)
      |> Enum.sum()
    end
  end

  defp undefrag_map(files, gaps) do
    files
    |> Enum.with_index()
    |> Enum.zip(Stream.concat(gaps, [0]))
    |> Enum.reduce({%{}, %{}, 0}, fn {{size, file_ix}, gap_after_size},
                                     {file_map, gap_map, start} ->
      {Map.put(file_map, file_ix, {start, size}), Map.put(gap_map, file_ix, start + size),
       start + size + gap_after_size}
    end)
  end

  defp gap_map([], _, _, builder), do: builder

  defp gap_map(files = [last_file_size | rest], rev_file_id, gaps, builder) do
    fits = Enum.find_index(gaps, fn gap -> gap >= last_file_size end)

    if fits do
      gap_map(
        rest,
        rev_file_id - 1,
        List.update_at(gaps, fits, &(&1 - last_file_size))
        |> Enum.reverse()
        |> Enum.drop(1)
        |> Enum.reverse(),
        Map.update(
          builder,
          fits,
          [{rev_file_id, last_file_size}],
          &(&1 ++ [{rev_file_id, last_file_size}])
        )
      )
    else
      gap_map(
        rest,
        rev_file_id - 1,
        gaps |> Enum.reverse() |> Enum.drop(1) |> Enum.reverse(),
        builder
      )
    end
  end

  defp fill_gap({gap_ix, move_files}, {file_map, empty_gap_map}) do
    Enum.reduce(move_files, {file_map, empty_gap_map}, fn {file_id, file_size},
                                                          {file_map, empty_gap_map} ->
      {Map.put(file_map, file_id, {Map.get(empty_gap_map, gap_ix), file_size}),
       Map.update!(empty_gap_map, gap_ix, &(&1 + file_size))}
    end)
  end
end

sample = "2333133121414131402"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))
IO.inspect(Day09.part_one(data), label: "Part one")
IO.inspect(Day09.part_two(data), label: "Part two")

"          11111111112222222222333333333334"
"012345678901234567890123456789012345678901"
"00992111777.44.333....5555.6666.....8888.."
