defmodule Battleship do
  def parse_state(raw_file) do
    file = Enum.map(raw_file, &String.trim/1)
    {boards, moves} = Enum.split(file, 21)

    %{
      boards: [
        Enum.take(boards, 10),
        Enum.take(boards, -10)
      ],
      moves: moves
    }
  end

  def load_state(file_path \\ "state.txt") do
    file_path |> File.stream!() |> parse_state
  end

  def active_player(state) do
    Integer.mod(length(state.moves), 2) + 1
  end

  def overlay(moves, board, fog \\ true) do
    n = length(board)

    Enum.map(0..(n - 1), fn y ->
      Enum.reduce(0..(n - 1), "", fn x, acc ->
        acc <> overlay_string(moves, board, fog, {y, x})
      end)
    end)
  end

  def index_string(board, {y, x}) do
    String.at(Enum.at(board, y), x)
  end

  def overlay_string(moves, board, fog, {y, x}) do
    if Enum.member?(moves, {y, x}) do
      case index_string(board, {y, x}) do
        "." ->
          "*"

        _ ->
          "#"
      end
    else
      (fog && "~") || index_string(board, {y, x})
    end
  end

  # stdio output - draw line by line
  def draw_boards(overlays) do
    Enum.zip_with(overlays, fn [p1_line, p2_line] ->
      IO.puts(p1_line <> " " <> p2_line)
    end)
  end

  def draw_state(state) do
    {p1, p2} = {Enum.take_every(state.moves, 2), Enum.drop_every(state.moves, 2)}
    [b1, b2] = state.boards

    player = active_player(state)

    draw_boards([
      overlay(p2, b1, player != 1),
      overlay(p1, b2, player != 2)
    ])
  end

  def process_turn(state) do
    draw_state(state)

    player = active_player(state) |> to_string()

    input = IO.gets("Player " <> player <> " move: ") |> String.upcase()

    # player input validation
    if String.match?(input, ~r/^([A-J]+\s*\(?\)?)\s*([1-9]|10)$/) do
      {row, col} = String.split_at(input, 1)

      {y, x} =
        {:binary.first(row) - 65, (String.trim(col) |> String.to_integer()) - 1}

      state = update_in(state.moves, &(&1 ++ [{y, x}]))
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
