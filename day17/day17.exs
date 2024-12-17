defmodule Machine do
  def run(program, state, max_output_len \\ 1000) do
    state = process_instruction(program, 0, Map.put(state, :output, []), max_output_len)
    state.output |> Enum.reverse() |> Enum.join(",")
  end

  defp process_instruction(program, instruction_pointer, state, _) when not is_map_key(program, instruction_pointer),
    do: state

  defp process_instruction(_, _, %{output: output}, max_output_len) when length(output) > max_output_len,
    do: %{output: []}

  defp process_instruction(program, instruction_pointer, state, max_output_len) do
    with opcode <- Map.get(program, instruction_pointer),
         opand <- Map.get(program, instruction_pointer + 1) do
      {new_state, new_ip} = Enum.at(all_opcodes(), opcode).(opand, state, instruction_pointer)
      process_instruction(program, new_ip + 2, new_state, max_output_len)
    end
  end

  defp all_opcodes(),
    do: [
      &adv/3,
      &bxl/3,
      &bst/3,
      &jnz/3,
      &bxc/3,
      &out/3,
      &bdv/3,
      &cdv/3
    ]

  defp combo(opand, state) do
    case opand do
      literal when literal <= 3 -> literal
      4 -> state[:a]
      5 -> state[:b]
      6 -> state[:c]
      7 -> raise("Combo opand 7")
    end
  end

  defp adv(opand, state, ip), do: {Map.put(state, :a, div(state[:a], 2 ** combo(opand, state))), ip}
  defp bxl(opand, state, ip), do: {Map.put(state, :b, Bitwise.bxor(state[:b], opand)), ip}
  defp bst(opand, state, ip), do: {Map.put(state, :b, rem(combo(opand, state), 8)), ip}
  defp jnz(_, state = %{a: 0}, ip), do: {state, ip}
  defp jnz(opand, state, _), do: {state, opand - 2}
  defp bxc(_, state, ip), do: {Map.put(state, :b, Bitwise.bxor(state[:b], state[:c])), ip}
  defp out(opand, state, ip), do: {Map.update!(state, :output, &["#{rem(combo(opand, state), 8)}" | &1]), ip}
  defp bdv(opand, state, ip), do: {Map.put(state, :b, div(state[:a], 2 ** combo(opand, state))), ip}
  defp cdv(opand, state, ip), do: {Map.put(state, :c, div(state[:a], 2 ** combo(opand, state))), ip}
end

# Part 1 - sample

prog_listing = [0, 1, 5, 4, 3, 0]
program = prog_listing |> Enum.with_index() |> Enum.map(fn {op, ix} -> {ix, op} end) |> Enum.into(%{})
state = %{a: 729, b: 0, c: 0}

IO.puts(Machine.run(program, state))

# Secret
prog_listing = []

prog_listing
|> Enum.reverse()
|> Enum.reduce([0], fn out, possible_a ->
  possible_a
  # |> Expand to range of values that divide to possible_a at previous step
  # |> Filter to values that have the correct output calculated at this step
end)
|> List.first()
|> IO.inspect(label: "Quine at")
