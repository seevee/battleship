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

  def load_state(file \\ "state.txt") do
    file |> File.stream!() |> parse_state
  end

  def active_player(state) do
    Integer.mod(length(state.moves), 2) + 1
  end

  def fog_overlay(moves, board) do
    n = length(board)

    Enum.map(0..(n - 1), fn y ->
      Enum.map(0..(n - 1), fn x ->
        if Enum.member?(moves, {y, x}) do
          case String.at(Enum.at(board, y), x) do
            "." ->
              "O"

            _ ->
              "X"
          end
        else
          "~"
        end
      end)
    end)
  end

  def draw_state(state) do
    # p1 and p2 alternate for both players
    {p1, p2} = {Enum.take_every(state.moves, 2), Enum.drop_every(state.moves, 2)}

    case active_player(state) do
      1 ->
        overlay = fog_overlay(p2, List.last(state.boards))

        Enum.zip_with([List.first(state.boards), Enum.map(overlay, &Enum.join/1)], fn [x, y] ->
          IO.puts(x <> " " <> y)
        end)

      2 ->
        overlay = fog_overlay(p2, List.first(state.boards))

        Enum.zip_with([Enum.map(overlay, &Enum.join/1), List.last(state.boards)], fn [x, y] ->
          IO.puts(x <> " " <> y)
        end)
    end
  end

  def process_turn(state) do
    draw_state(state)
    input = String.upcase(IO.gets("Player " <> to_string(active_player(state)) <> " move: "))

    # Input validation
    if String.match?(input, ~r/^([A-J]+\s*\(?\)?)\s*([1-9]|10)$/) do
      {row, col} = String.split_at(input, 1)

      {y, x} =
        {:binary.first(row) - 65, String.to_integer(String.trim(col)) - 1}

      state = update_in(state.moves, &[{y, x} | &1])

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
