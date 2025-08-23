defmodule Battleship do
  def parse_state(raw_file) do
    file = Enum.map(raw_file, &String.trim/1)
    n = List.first(file) |> String.length()
    {boards, moves} = Enum.split(file, 2 * n + 1)

    %{
      boards: {
        Enum.take(boards, n),
        Enum.take(boards, -n)
      },
      moves: moves
    }
  end

  def load_state(file_path \\ "state.txt") do
    file_path |> File.stream!() |> parse_state
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
    if Enum.member?(moves, move) do
      case cell(board, move) do
        "." ->
          fmt_miss("*")

        _ ->
          fmt_hit("#")
      end
    else
      (fog && "~") || cell(board, move)
    end
  end

  def fmt(str, {r1, g1, b1}, {r2, g2, b2}) do
    IO.ANSI.color(r1, g1, b1) <> IO.ANSI.color_background(r2, g2, b2) <> str <> IO.ANSI.reset()
  end

  def fmt_hit(str) do
    fmt(str, {4, 4, 0}, {3, 0, 0})
  end

  def fmt_miss(str) do
    fmt(str, {4, 3, 3}, {0, 0, 1})
  end

  # stdio output - draw line by line
  def draw_boards(overlays) do
    Enum.zip_with(overlays, fn [p1_line, p2_line] ->
      IO.puts(p1_line <> " " <> p2_line)
    end)
  end

  def draw_state(state) do
    {p1, p2} = {Enum.take_every(state.moves, 2), Enum.drop_every(state.moves, 2)}
    {b1, b2} = state.boards

    player = active_player(state)

    draw_boards([
      overlay(p2, b1, player != 1),
      overlay(p1, b2, player != 2)
    ])
  end

  def process_turn(state) do
    draw_state(state)

    player = active_player(state)

    input = IO.gets("Player " <> to_string(player) <> " move: ") |> String.upcase()

    # player input validation
    if String.match?(input, ~r/^([A-J]+\s*\(?\)?)\s*([1-9]|10)$/) do
      {row, col} = String.split_at(input, 1)

      move =
        {:binary.first(row) - 65, (String.trim(col) |> String.to_integer()) - 1}

      result =
        case cell(elem(state.boards, Integer.mod(player, 2)), move) do
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

  def play(state \\ load_state()) do
    process_turn(state)
  end
end

Battleship.play()
