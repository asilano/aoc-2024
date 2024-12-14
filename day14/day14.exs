# Can probably do this with simple multiplication and modulus.
defmodule Robot do
  defstruct [:px, :py, :dx, :dy]

  def parse(line) do
    with [px, py, dx, dy] <- Regex.run(regex(), line) |> Enum.drop(1) |> Enum.map(&String.to_integer/1) do
      %Robot{px: px, py: py, dx: dx, dy: dy}
    end
  end

  def step_n(robot, steps, width, height) do
    %Robot{
      robot
      | px: rem(rem(robot.px + steps * robot.dx, width) + width, width),
        py: rem(rem(robot.py + steps * robot.dy, height) + height, height)
    }
  end

  defp regex(), do: ~r/^p=(-?\d+),(-?\d+) v=(-?\d+),(-?\d+)$/
end

defmodule Day14 do
  def part_one(data, width, height) do
    with robots <- parse_data(data) do
      Enum.map(robots, &Robot.step_n(&1, 100, width, height))
      |> quadrants(width, height)
      |> Enum.map(&length/1)
      |> Enum.product()
    end
  end

  def part_two(data, width, height) do
    with robots <- parse_data(data) do
      Enum.each(1..100_000, fn n ->
        with robots <- Enum.map(robots, &Robot.step_n(&1, n, width, height)),
             adjacency when adjacency >= 230 <- count_adjacency(robots) do
          IO.puts("")
          IO.puts("#{adjacency} adjacent at #{n}")
          dump_robots(robots, width, height)
        end
      end)
    end
  end

  defp parse_data(data) do
    data |> String.split("\n") |> Enum.map(&Robot.parse/1)
  end

  defp quadrants(robots, width, height) do
    [
      Enum.filter(robots, fn %Robot{px: px, py: py} -> px < div(width, 2) && py < div(height, 2) end),
      Enum.filter(robots, fn %Robot{px: px, py: py} -> px > div(width, 2) && py < div(height, 2) end),
      Enum.filter(robots, fn %Robot{px: px, py: py} -> px < div(width, 2) && py > div(height, 2) end),
      Enum.filter(robots, fn %Robot{px: px, py: py} -> px > div(width, 2) && py > div(height, 2) end)
    ]
  end

  defp count_adjacency(robots) do
    Enum.count(robots, fn robot = %Robot{px: px, py: py} ->
      Enum.any?(robots, &(robot != &1 && abs(px - &1.px) + abs(py - &1.py) <= 1))
    end)
  end

  defp dump_robots(robots, width, height) do
    for y <- 0..(height - 1), x <- 0..(width - 1) do
      if x == 0, do: IO.puts("")

      if Enum.any?(robots, &(&1.px == x && &1.py == y)) do
        IO.write("#")
      else
        IO.write(" ")
      end
    end
  end
end

sample = "p=0,4 v=3,-3
p=6,3 v=-1,-3
p=10,3 v=-1,2
p=2,0 v=2,-1
p=0,0 v=1,3
p=3,0 v=-2,-2
p=7,6 v=-1,-3
p=3,0 v=-1,-2
p=9,3 v=2,3
p=7,3 v=-1,2
p=2,4 v=2,-3
p=9,5 v=-3,-3"
data = to_string(File.read!(Path.join(__DIR__, "data.txt")))

IO.inspect(Day14.part_one(data, 101, 103))
IO.inspect(Day14.part_two(data, 101, 103))
