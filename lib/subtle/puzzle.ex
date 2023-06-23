defmodule Subtle.Puzzle do
  @moduledoc """
  Subtle is a Wordle clone for me to learn Elixir
  """

  alias Subtle.{Puzzle, Guess}

  @max_guesses 5

  @enforce_keys [:state, :answer, :guesses]
  defstruct [
    state: :playing,
    answer: "",
    max_guesses: @max_guesses,
    guesses: []
  ]

  def new() do
    Puzzle.new(random_puzzle_word())
  end
  def new(answer) do
    %Puzzle{state: :playing, answer: answer,
             max_guesses: @max_guesses, guesses: []}
  end

  def make_guess(%Puzzle{state: :playing} = puzzle, guess) do
    case Guess.guess_word(guess, puzzle.answer) do
      {:ok, :correct, guess_result} ->
        # correct guess will transition the puzzle to :game_won
        {:ok, change_state_and_add_guess(puzzle, :game_won, guess_result)}
      {:ok, :incorrect, guess_result} ->
        # incorrect guess will update the puzzle and check for :game_over
        case last_guess?(puzzle) do
          true ->
            {:ok, change_state_and_add_guess(puzzle, :game_over, guess_result)}
          false ->
            {:ok, add_guess(puzzle, guess_result)}
        end
      # don't pass in garbage!
      {:error, :invalid_length} -> {:error, puzzle, :invalid_length}
      {:error, _} -> {:error, puzzle, :baby_dont_hurt_me}
    end
  end
  def make_guess(puzzle, _), do: {:error, puzzle, :game_over}


  def change_state_and_add_guess(puzzle, state, guess_result) do
    # this works but I feel it's not the 'right' way
    %Puzzle{puzzle | state: state}
    |> add_guess(guess_result)
  end

  def add_guess(puzzle, guess_result) do
    # this works but I feel it's not the 'right' way
    %Puzzle{state: puzzle.state, answer: puzzle.answer,
      guesses: List.insert_at(puzzle.guesses, -1, guess_result)}
  end

  @doc"""
  Returns true if we haven't exceeded the maximum guesses
  """
  def guesses_remaining?(puzzle) do
    Enum.count(puzzle.guesses) < puzzle.max_guesses
  end

  def guesses_remaining(puzzle) do
    puzzle.max_guesses - Enum.count(puzzle.guesses)
  end

  @doc"""
  Returns true if, by adding one more guess, we will
  have @max_guesses
  """
  def last_guess?(puzzle) do
    Enum.count(puzzle.guesses) >= (puzzle.max_guesses - 1)
  end

  @doc"""
  Returns a list of guesses, padded with empty guesses
  """
  def normalized_guesses(puzzle) do
    Enum.concat(puzzle.guesses, empty_guesses(puzzle))
  end

  def empty_guesses(puzzle) do
    Enum.reduce(1..Puzzle.guesses_remaining(puzzle),
      [], fn _i, acc -> [empty_guess(puzzle) | acc] end)
  end

  def empty_guess(puzzle) do
    answer_letters = String.graphemes(puzzle.answer)
    results = Enum.reduce(
      answer_letters, [],
      fn _x, acc -> [{" ", :none} | acc] end)
    %Guess{guess: String.duplicate(" ", Enum.count(answer_letters)),
      results: results}
  end

  @doc """
  This will return a string describing the current state of the game.
  It shows the current state, the answer to the puzzle,
  and a list of any guesses made so far. Each guess will show
  a '!' before any wrong letter and '~' to show a correct letter
  in the wrong position.

  See `Guess`.guess_word/2 to understand the guess structure.

  ### Examples
      Given a puzzle with answer "paper", guess "apple"

      iex> puzzle = Puzzle.new("paper")
      iex> {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      iex> Puzzle.summary(puzzle)
      "Puzzle: state: playing, answer: paper, [~a~pp!l~e]"

      This shows there is an "a" in another postion, the first "p"
      is in the wrong position, the third "p" is correct, there
      is no "l", and the final "e" is in the wrong postion.
  """
  def summary(puzzle) do
    summary =
      "Puzzle: " <>
      "state: " <> Atom.to_string(puzzle.state) <> ", " <>
      "answer: " <> puzzle.answer <> ", " <>
      Enum.reduce(puzzle.guesses, "[",
        fn %Guess{} = guess,
          acc -> acc <> guess_summary(guess.results) <> ", " end)
    String.replace_suffix(summary, ", ", "") <> "]"
  end
  defp guess_summary(results) do
    Enum.reduce(results, "",
      fn {_l, _p} = result, acc -> acc <> result_summary(result) end)
  end
  defp result_summary({letter, position}) do
    case position do
      :correct -> letter
      :wrong_position -> "~" <> letter
      :wrong_letter -> "!" <> letter
      _ -> "."
    end
  end

  @doc """
  Get a random word from our list of puzzle words.

  ### Examples

      iex> Puzzle.random_puzzle_word()
      # "paper"

  """
  def random_puzzle_word() do
    puzzle_words()
    |> Enum.random()
  end

  # Ideally we would cache this, but for now it's simple and blazing fast
  def puzzle_words() do
    :code.priv_dir(:subtle)
    |> Path.join("/puzzle_files/puzzle_words.txt")
    |> File.read!()
    |> String.split("\n")
  end

end
