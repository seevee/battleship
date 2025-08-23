defmodule Battleship do
  def load_state(file_path \\ "state.txt") do
    file = file_path |> File.stream!() |> Enum.map(&String.trim/1)
    n = file |> List.first() |> String.length()
    {boards, moves} = Enum.split(file, 2 * n + 1)

    %{
      boards: [
        Enum.take(boards, n),
        Enum.take(boards, -n)
      ],
      moves:
        Enum.reduce(moves, [], fn move, acc ->
          acc ++
            [
              move
              |> String.split()
              |> Enum.map(&String.to_integer/1)
              |> List.to_tuple()
            ]
        end),
      file_path: file_path
    }
  end

  def player_moves(state) do
    [Enum.take_every(state.moves, 2), Enum.drop_every(state.moves, 2)]
  end

  def active_player(state) do
    Integer.mod(length(state.moves), 2) + 1
  end

  def cell(board, {y, x}) do
    String.at(Enum.at(board, y), x)
  end

  def overlay(moves, board, fog) do
    n = length(board)

    Enum.map(0..(n - 1), fn y ->
      Enum.reduce(0..(n - 1), "", fn x, acc ->
        acc <> overlay(moves, board, fog, {y, x})
      end)
    end)
  end

  def overlay(moves, board, fog, move) do
    char = cell(board, move)

    if Enum.member?(moves, move) do
      case char do
        "." ->
          fmt_miss("*")

        _ ->
          fmt_hit(char)
      end
    else
      (fog && "~") || char
    end
  end

  def format_string(str, {r1, g1, b1}, {r2, g2, b2}) do
    IO.ANSI.color(r1, g1, b1) <> IO.ANSI.color_background(r2, g2, b2) <> str <> IO.ANSI.reset()
  end

  def fmt_hit(str) do
    format_string(str, {4, 4, 0}, {3, 0, 0})
  end

  def fmt_miss(str) do
    format_string(str, {4, 3, 3}, {0, 0, 1})
  end

  def draw_state(state) do
    [p1, p2] = player_moves(state)
    [b1, b2] = state.boards

    player = active_player(state)

    Enum.zip_with(
      [
        overlay(p2, b1, player != 1),
        overlay(p1, b2, player != 2)
      ],
      fn [o1_line, o2_line] ->
        IO.puts(o1_line <> " " <> o2_line)
      end
    )
  end

  def process_turn(state \\ load_state()) do
    draw_state(state)

    player = active_player(state)

    input = IO.gets("Player " <> to_string(player) <> " move: ") |> String.upcase()

    IO.puts(IO.ANSI.clear())

    IO.puts(inspect(state))

    # player input validation
    if String.match?(input, ~r/^([A-J]+\s*\(?\)?)\s*([1-9]|10)$/) do
      {row, col} = String.split_at(input, 1)

      move =
        {:binary.first(row) - 65, (col |> String.trim() |> String.to_integer()) - 1}

      result =
        case cell(Enum.at(state.boards, Integer.mod(player, 2)), move) do
          "." -> fmt_miss("MISS")
          _ -> fmt_hit("HIT")
        end

      IO.puts(result)

      state = update_in(state.moves, &(&1 ++ [move]))

      process_turn(state)
    else
      IO.puts("Invalid move - Try again")
      process_turn(state)
    end
  end
end

IO.puts(IO.ANSI.clear())
Battleship.process_turn()
