defmodule Battleship do
  defp parse(raw_shot) when is_binary(raw_shot) do
    raw_shot
    |> String.split()
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end

  defp parse(raw_shots) when is_list(raw_shots) do
    raw_shots
    |> Enum.reduce([], fn shot, acc -> [parse(shot) | acc] end)
    |> Enum.reverse()
    |> then(fn shots ->
      %{
        1 => Enum.take_every(shots, 2),
        2 => Enum.drop_every(shots, 2)
      }
    end)
  end

  defp load_state(file_path \\ "state.txt") do
    file =
      file_path
      |> File.stream!()
      |> Enum.map(&String.trim/1)

    n =
      file
      |> List.first()
      |> String.length()

    {raw_boards, raw_shots} = Enum.split(file, 2 * n)

    %{
      boards: raw_boards |> Enum.split(n) |> Tuple.to_list(),
      shots: parse(raw_shots),
      file_path: file_path,
      active_player: raw_shots |> length() |> Integer.mod(2) |> Kernel.+(1)
    }
  end

  defp cell(board, {y, x}) do
    board |> Enum.at(y) |> String.at(x)
  end

  defp format_string(str, {r1, g1, b1}, {r2, g2, b2}) do
    IO.ANSI.color(r1, g1, b1) <>
      IO.ANSI.color_background(r2, g2, b2) <>
      str <>
      IO.ANSI.reset()
  end

  defp fmt(str, mode) when mode === :hit do
    format_string(str, {4, 4, 0}, {3, 0, 0})
  end

  defp fmt(str, mode) when mode === :miss do
    format_string(str, {4, 3, 3}, {0, 0, 1})
  end

  defp overlay(shots, board, fog, {y, x}) do
    char = cell(board, {y, x})

    cond do
      {y, x} not in shots -> (fog && "~") || char
      char in ["."] -> fmt("*", :miss)
      true -> fmt(char, :hit)
    end
  end

  defp overlay(shots, board, fog) do
    range = 0..(length(board) - 1)

    Enum.map(range, fn y ->
      Enum.reduce(range, "", fn x, acc ->
        acc <> overlay(shots, board, fog, {y, x})
      end)
    end)
  end

  defp draw(state) do
    [b1, b2] = state.boards
    [f1, f2] = [state.active_player != 1, state.active_player != 2]

    overlays = [
      overlay(state.shots[2], b1, f1),
      overlay(state.shots[1], b2, f2)
    ]

    Enum.zip_with(overlays, fn [o1_line, o2_line] ->
      IO.puts(o1_line <> " " <> o2_line)
    end)

    state
  end

  defp process_input(state) do
    upcase_input =
      state.active_player
      |> to_string()
      |> then(&"Player #{&1} shot: ")
      |> IO.gets()
      |> String.upcase()

    {row, col} = String.split_at(upcase_input, 1)

    shot = {
      :binary.first(row) - 65,
      col |> String.trim() |> String.to_integer() |> Kernel.-(1)
    }

    cond do
      !String.match?(upcase_input, ~r/^([A-J]+\s*\(?\)?)\s*([1-9]|10)$/) ->
        IO.puts("Invalid shot - Try again")
        process_input(state)

      shot in state.shots[state.active_player] ->
        IO.puts("Shot already taken - Try again")
        process_input(state)

      true ->
        update_in(state.shots[state.active_player], &(&1 ++ [shot]))
    end
  end

  defp process_shot(state) do
    enemy_index = Integer.mod(state.active_player, 2)
    enemy_board = Enum.at(state.boards, enemy_index)
    shot = List.last(state.shots[state.active_player])

    result =
      case cell(enemy_board, shot) do
        "." -> fmt("MISS", :miss)
        _ -> fmt("HIT", :hit)
      end

    IO.puts(result)
    state
  end

  defp switch_player(state) do
    enemy_index = Integer.mod(state.active_player, 2)
    Map.replace(state, :active_player, enemy_index + 1)
  end

  def process_turn(state \\ load_state()) do
    state
    |> draw()
    |> process_input()
    |> process_shot()
    |> switch_player()
    |> process_turn()
  end
end

IO.puts(IO.ANSI.clear())
Battleship.process_turn()
