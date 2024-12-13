defmodule Machine do
  defstruct [:ax, :ay, :bx, :by, :px, :py]

  def parse(data, offset \\ 0) do
    with [a_line, b_line, prize_line] <- String.split(data, "\n"),
         [_, ax, ay] <- Regex.run(line_regex(), a_line),
         [_, bx, by] <- Regex.run(line_regex(), b_line),
         [_, px, py] <- Regex.run(line_regex(), prize_line) do
      %Machine{
        ax: String.to_integer(ax),
        ay: String.to_integer(ay),
        bx: String.to_integer(bx),
        by: String.to_integer(by),
        px: String.to_integer(px) + offset,
        py: String.to_integer(py) + offset
      }
    end
  end

  def solve(machine) do
    # Solve the system:
    # Aax + Bbx = px
    # Aay + Bby = py
    # => (A =) px / ax - Bbx / ax = py / ay - Bby / ay
    # => px / ax - py / ay = Bbx / ax - Bby / ay
    # => px.ay - py.ax = Bbx.ay - Bby.ax
    #                  = B(bx.ay - by.ax)
    # => B = (px.ay - py.ax) / (bx.ay - by.ax)
    with b_numer = machine.px * machine.ay - machine.py * machine.ax,
         b_denom = machine.bx * machine.ay - machine.by * machine.ax,
         b_integer when b_integer <- rem(b_numer, b_denom) == 0,
         b <- div(b_numer, b_denom),
         a_numer <- machine.px - b * machine.bx,
         a_denom <- machine.ax,
         a_integer when a_integer <- rem(a_numer, a_denom) == 0,
         a <- div(a_numer, a_denom) do
      {a, b}
    else
      _ -> false
    end
  end

  defp line_regex() do
    ~r/X[+=](\d+), Y[+=](\d+)$/
  end
end

defmodule Day13 do
  def part_one(data) do
    data
    |> parse_machines()
    |> Enum.map(&Machine.solve/1)
    |> Enum.filter(& &1)
    |> Enum.map(fn {a, b} -> 3 * a + b end)
    |> Enum.sum()
  end

  def part_two(data) do
    data
    |> parse_machines(10_000_000_000_000)
    |> Enum.map(&Machine.solve/1)
    |> Enum.filter(& &1)
    |> Enum.map(fn {a, b} -> 3 * a + b end)
    |> Enum.sum()
  end

  defp parse_machines(data, offset \\ 0) do
    data |> String.split("\n\n") |> Enum.map(&Machine.parse(&1, offset))
  end
end

sample = "Button A: X+94, Y+34
Button B: X+22, Y+67
Prize: X=8400, Y=5400

Button A: X+26, Y+66
Button B: X+67, Y+21
Prize: X=12748, Y=12176

Button A: X+17, Y+86
Button B: X+84, Y+37
Prize: X=7870, Y=6450

Button A: X+69, Y+23
Button B: X+27, Y+71
Prize: X=18641, Y=10279"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day13.part_one(data))
IO.inspect(Day13.part_two(data))
