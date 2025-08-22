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

  def fog_overlay(moves, n) do
    Enum.map(0..(n - 1), fn y ->
      Enum.map(0..(n - 1), fn x ->
        if Enum.member?(moves, {y, x}) do
          "X"
        else
          "~"
        end
      end)
    end)
  end

  def move_overlay(state) do
    # p1 and p2 alternate for both players
    {p1, p2} = {Enum.take_every(state.moves, 2), Enum.drop_every(state.moves, 2)}
    IO.puts(inspect(p1))
    IO.puts(inspect(p2))

    case active_player(state) do
      1 ->
        overlay = fog_overlay(p2, 10)

        IO.puts(inspect(overlay))
        # draw fog for enemy, hits and misses for enemy and self
        nil

      2 ->
        overlay = fog_overlay(p2, 10)

        IO.puts(inspect(overlay))
        nil
    end
  end

  def draw_state(state) do
    Enum.zip_with(state.boards, fn [x, y] -> IO.puts(x <> " " <> y) end)
  end

  def process_turn(state) do
    input = String.upcase(IO.gets("Player " <> to_string(active_player(state)) <> " move: "))

    # Input validation
    if String.match?(input, ~r/^([A-J]+\s*\(?\)?)\s*([1-9]|10)$/) do
      {row, col} = String.split_at(input, 1)

      {y, x} =
        {:binary.first(row) - 65, String.to_integer(String.trim(col)) - 1}

      state = update_in(state.moves, &[{y, x} | &1])

      draw_state(state)
      move_overlay(state)
      process_turn(state)
    else
      IO.puts("Invalid move - Try again")
      process_turn(state)
    end
  end

  def play(state \\ load_state()) do
    draw_state(state)

    case process_turn(state) do
      :ok ->
        IO.puts("Game Over")

      _ ->
        nil
    end
  end
end

Battleship.play()
