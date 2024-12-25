defmodule Day24 do
  def part_one(data) do
    {active_wires, gates} = parse_data(data)

    run_system(active_wires, gates)
    |> Enum.filter(fn {k, _} -> String.starts_with?(k, "z") end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.reverse()
    |> Enum.map(fn {_, val} -> if val, do: "1", else: "0" end)
    |> Enum.join()
    |> String.to_integer(2)
  end

  def part_two(data, bit_max) do
    {gates, reverse_gates} = parse_data_into_just_gates(data)

    check_half_adder(gates, reverse_gates, 0, bit_max, nil, [])
    |> Enum.sort()
    |> Enum.uniq()
    |> Enum.join(",")
  end

  defp run_system(active_wires, gates) when map_size(gates) == 0, do: active_wires

  defp run_system(active_wires, gates) do
    next =
      {wire_a, wire_b} =
      gates
      |> Map.keys()
      |> Enum.find(fn {wire_a, wire_b} ->
        Map.has_key?(active_wires, wire_a) and Map.has_key?(active_wires, wire_b)
      end)

    next_gates = Map.get(gates, next)

    input_a = Map.get(active_wires, wire_a)
    input_b = Map.get(active_wires, wire_b)

    active_wires =
      Enum.reduce(next_gates, active_wires, fn {op, out_wire}, wires ->
        out_signal =
          case op do
            "AND" -> input_a and input_b
            "OR" -> input_a or input_b
            "XOR" -> input_a != input_b
          end

        Map.put(wires, out_wire, out_signal)
      end)

    run_system(active_wires, Map.delete(gates, next))
  end

  defp check_half_adder(_, _, n, max_n, _, errors) when n > max_n, do: errors

  defp check_half_adder(gates, reverse_gates, n, max_n, carry_in, errors) do
    input_id = n |> Integer.to_string() |> String.pad_leading(2, "0")
    output_wire = "z#{input_id}"
    half_adder_xor_key = {"x#{input_id}", "y#{input_id}", "XOR"}
    half_adder_and_key = {"x#{input_id}", "y#{input_id}", "AND"}

    half_adder_xor_out = Map.get(gates, half_adder_xor_key)
    half_adder_and_out = Map.get(gates, half_adder_and_key)

    # When no carry present, the XOR should be the output bit (only z00)
    if is_nil(carry_in) do
      errors =
        if half_adder_xor_out != output_wire do
          IO.inspect(half_adder_xor_out, label: "Adding 1")
          IO.inspect(output_wire, label: "Adding 1b")
          [half_adder_xor_out, output_wire | errors]
        else
          errors
        end

      # Recurse into the first with-carry case
      check_half_adder(gates, reverse_gates, n + 1, max_n, half_adder_and_out, errors)
    else
      # When carry is present, then there should be
      # * an XOR with carry and half_adder_xor_out, leading to the output bit
      # * an AND with carry and half_adder_xor_out, leading to a temp
      # * an OR  with temp and half_added_and_out, which is the next carry
      # If the XOR is missing, then use reverse gates map to find the gate which outputs the output bit,
      # and use it to determine which of carry and haxo is wrong.
      # Once the XOR is determined, the AND cannot be missing (only outputs are swapped)
      # If the OR is missing, then temp or the haao is wrong; search the gates for an OR with haao or temp
      # If either of temp or carry is a z##, then it's wrong (but we might detect that anyway!)
      #
      # This is not totally robust, if enough nearby errors exist.
      xor_inputs = [xor_input_a, xor_input_b] = Enum.sort([carry_in, half_adder_xor_out])
      output_gate = Map.get(gates, {xor_input_a, xor_input_b, "XOR"})

      {errors, output_gate, carry_in, half_adder_xor_out} =
        if is_nil(output_gate) do
          {gate_in_a, gate_in_b, "XOR"} = Map.get(reverse_gates, output_wire)

          {errors, c, haxo} =
            if carry_in in [gate_in_a, gate_in_b] do
              IO.inspect(half_adder_xor_out, label: "Adding 2")

              {[half_adder_xor_out | errors], carry_in,
               cond do
                 carry_in == gate_in_a -> gate_in_b
                 carry_in == gate_in_b -> gate_in_a
               end}
            else
              IO.inspect(carry_in, label: "Adding 3")

              {[carry_in | errors],
               cond do
                 half_adder_xor_out == gate_in_a -> gate_in_b
                 half_adder_xor_out == gate_in_b -> gate_in_a
               end, half_adder_xor_out}
            end

          {errors, output_wire, c, haxo}
        else
          {errors, output_gate, carry_in, half_adder_xor_out}
        end

      errors =
        if output_gate != output_wire do
          IO.inspect(output_gate, label: "Adding 4")
          IO.inspect(output_wire, label: "Adding 4b")
          [output_gate, output_wire | errors]
        else
          errors
        end

      [and_input_a, and_input_b] = Enum.sort([carry_in, half_adder_xor_out])

      temp = Map.get(gates, {and_input_a, and_input_b, "AND"})
      if is_nil(temp), do: raise("temp is nil!")

      [or_input_a, or_input_b] = Enum.sort([temp, half_adder_and_out])
      carry_out = Map.get(gates, {or_input_a, or_input_b, "OR"})

      {errors, carry_out} =
        if is_nil(carry_out) do
          result =
            Enum.find(gates, fn {{a, b, op}, _} ->
              op == "OR" and (a == half_adder_and_out or b == half_adder_and_out)
            end)

          if result do
            {_, correct_carry_gate} = result

            IO.inspect(temp, label: "Adding 5")
            {[temp | errors], correct_carry_gate}
          else
            result =
              Enum.find(gates, fn {{a, b, op}, _} ->
                op == "OR" and (a == temp or b == temp)
              end)

            {_, correct_carry_gate} = result

            IO.inspect(half_adder_and_out, label: "Adding 6")
            {[half_adder_and_out | errors], correct_carry_gate}
          end
        else
          {errors, carry_out}
        end

      check_half_adder(gates, reverse_gates, n + 1, max_n, carry_out, errors)
    end
  end

  defp parse_data(data) do
    [wires_part, gates_part] = String.split(data, "\n\n")
    {parse_wires(wires_part), parse_gates(gates_part)}
  end

  defp parse_wires(wires_data) do
    wires_data
    |> String.split("\n")
    |> Enum.reduce(%{}, fn line, active_wires ->
      [wire_name, signal] = String.split(line, ": ")
      Map.put(active_wires, wire_name, signal == "1")
    end)
  end

  defp parse_gates(gates_data) do
    gates_data
    |> String.split("\n")
    |> Enum.reduce(%{}, fn line, gates ->
      [wire_a, op, wire_b, _, wire_out] = String.split(line)
      [wire_a, wire_b] = Enum.sort([wire_a, wire_b])
      Map.update(gates, {wire_a, wire_b}, [{op, wire_out}], &[{op, wire_out} | &1])
    end)
  end

  defp parse_data_into_just_gates(data) do
    [_, gates_part] = String.split(data, "\n\n")

    gates_part
    |> String.split("\n")
    |> Enum.reduce({%{}, %{}}, fn line, {gates, rev} ->
      [wire_a, op, wire_b, _, wire_out] = String.split(line)
      [wire_a, wire_b] = Enum.sort([wire_a, wire_b])
      {Map.put(gates, {wire_a, wire_b, op}, wire_out), Map.put(rev, wire_out, {wire_a, wire_b, op})}
    end)
  end
end

data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day24.part_one(data))
IO.inspect(Day24.part_two(data, 44))
