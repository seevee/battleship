defmodule Battleship do
  def parse_move(move) do
    move
    |> String.split()
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end

  def load_state(file_path \\ "state.txt") do
    file =
      file_path
      |> File.stream!()
      |> Enum.map(&String.trim/1)

    n =
      file
      |> List.first()
      |> String.length()

    {boards, moves} = Enum.split(file, 2 * n + 1)

    %{
      boards: [
        Enum.take(boards, n),
        Enum.take(boards, -n)
      ],
      moves:
        moves
        |> Enum.reduce([], fn move, acc -> [parse_move(move) | acc] end)
        |> Enum.reverse(),
      file_path: file_path
    }
  end

  def player_moves(state) do
    [
      Enum.take_every(state.moves, 2),
      Enum.drop_every(state.moves, 2)
    ]
  end

  def active_player(state) do
    state.moves |> length() |> Integer.mod(2) |> Kernel.+(1)
  end

  def cell(board, {y, x}) do
    board |> Enum.at(y) |> String.at(x)
  end

  def format_string(str, {r1, g1, b1}, {r2, g2, b2}) do
    IO.ANSI.color(r1, g1, b1) <>
      IO.ANSI.color_background(r2, g2, b2) <>
      str <>
      IO.ANSI.reset()
  end

  def fmt(str, mode) when mode === :hit do
    format_string(str, {4, 4, 0}, {3, 0, 0})
  end

  def fmt(str, mode) when mode === :miss do
    format_string(str, {4, 3, 3}, {0, 0, 1})
  end

  def overlay(moves, board, fog, move) do
    char = cell(board, move)

    if move in moves do
      case char do
        "." -> fmt("*", :miss)
        _ -> fmt(char, :hit)
      end
    else
      (fog && "~") || char
    end
  end

  def overlay(moves, board, fog) do
    range =
      board
      |> length()
      |> Kernel.-(1)
      |> then(&(0..&1))

    Enum.map(range, fn y ->
      Enum.reduce(range, "", fn x, acc ->
        acc <> overlay(moves, board, fog, {y, x})
      end)
    end)
  end

  def draw(state) do
    [p1, p2] = player_moves(state)
    [b1, b2] = state.boards
    [f1, f2] = state |> active_player() |> then(&[&1 != 1, &1 != 2])

    overlays = [
      overlay(p2, b1, f1),
      overlay(p1, b2, f2)
    ]

    Enum.zip_with(overlays, fn [o1_line, o2_line] ->
      IO.puts(o1_line <> " " <> o2_line)
    end)
  end

  def process_turn(state \\ load_state()) do
    draw(state)

    player = active_player(state)

    input =
      player
      |> to_string
      |> then(&"Player #{&1} move: ")
      |> IO.gets()
      |> String.upcase()

    IO.puts(IO.ANSI.clear())

    # player input validation
    if String.match?(input, ~r/^([A-J]+\s*\(?\)?)\s*([1-9]|10)$/) do
      {row, col} = String.split_at(input, 1)

      move =
        {
          :binary.first(row) - 65,
          col |> String.trim() |> String.to_integer() |> Kernel.-(1)
        }

      previous_moves = state |> player_moves() |> Enum.at(player - 1)

      cond do
        move in previous_moves ->
          IO.puts("Move already made - Try again")
          process_turn(state)

        true ->
          enemy_index = Integer.mod(player, 2)

          state.boards
          |> Enum.at(enemy_index)
          |> cell(move)
          |> case do
            "." -> fmt("MISS", :miss)
            _ -> fmt("HIT", :hit)
          end
          |> IO.puts()

          state = update_in(state.moves, &(&1 ++ [move]))
          process_turn(state)
      end
    else
      IO.puts("Invalid move - Try again")
      process_turn(state)
    end
  end
end

IO.puts(IO.ANSI.clear())
Battleship.process_turn()
