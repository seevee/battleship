defmodule Battleship do
  def parse_shots(shots) do
    shots
    |> Enum.reduce([], fn shot, acc -> [parse_shot(shot) | acc] end)
    |> Enum.reverse()
  end

  def parse_shot(shot) do
    shot
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

    {boards, shots} =
      file
      |> Enum.split(2 * n)
      |> then(fn {b, s} ->
        {
          [Enum.take(b, n), Enum.take(b, -n)],
          parse_shots(s)
        }
      end)

    %{
      boards: boards,
      shots: shots,
      file_path: file_path,
      active_player: shots |> length() |> Integer.mod(2) |> Kernel.+(1)
    }
  end

  def player_shots(state) do
    [
      Enum.take_every(state.shots, 2),
      Enum.drop_every(state.shots, 2)
    ]
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

  def overlay(shots, board, fog, position) do
    char = cell(board, position)

    cond do
      position not in shots -> (fog && "~") || char
      char in ["."] -> fmt("*", :miss)
      true -> fmt(char, :hit)
    end
  end

  def overlay(shots, board, fog) do
    range =
      board
      |> length()
      |> Kernel.-(1)
      |> then(&(0..&1))

    Enum.map(range, fn y ->
      Enum.reduce(range, "", fn x, acc ->
        acc <> overlay(shots, board, fog, {y, x})
      end)
    end)
  end

  def draw(state) do
    [p1, p2] = player_shots(state)
    [b1, b2] = state.boards
    [f1, f2] = [state.active_player != 1, state.active_player != 2]

    overlays = [
      overlay(p2, b1, f1),
      overlay(p1, b2, f2)
    ]

    Enum.zip_with(overlays, fn [o1_line, o2_line] ->
      IO.puts(o1_line <> " " <> o2_line)
    end)
  end

  def process_shot(state, input) do
    {row, col} = String.split_at(input, 1)

    shot =
      {
        :binary.first(row) - 65,
        col |> String.trim() |> String.to_integer() |> Kernel.-(1)
      }

    previous_shots = state |> player_shots() |> Enum.at(state.active_player - 1)

    if shot in previous_shots do
      IO.puts("Shot already taken - Try again")
      process_input(state)
    else
      enemy_index = Integer.mod(state.active_player, 2)

      state.boards
      |> Enum.at(enemy_index)
      |> cell(shot)
      |> case do
        "." -> fmt("MISS", :miss)
        _ -> fmt("HIT", :hit)
      end
      |> IO.puts()

      update_in(state.shots, &(&1 ++ [shot]))
    end
  end

  def process_input(state) do
    input =
      state.active_player
      |> to_string()
      |> then(&"Player #{&1} shot: ")
      |> IO.gets()
      |> String.upcase()

    if !String.match?(input, ~r/^([A-J]+\s*\(?\)?)\s*([1-9]|10)$/) do
      IO.puts("Invalid shot - Try again")
      process_input(state)
    else
      process_shot(state, input)
    end
  end

  def process_turn(state \\ load_state()) do
    draw(state)

    state
    |> process_input()
    |> Map.replace(:active_player, Integer.mod(state.active_player, 2) + 1)
    |> process_turn()
  end
end

IO.puts(IO.ANSI.clear())
Battleship.process_turn()
