defmodule Subtle.Puzzle do
  @moduledoc """
  Subtle is a Wordle clone for me to learn Elixir
  """

  alias Subtle.{Puzzle, Guess, PuzzleDictionary}

  # don't change word length since we only have 5 letter words in dict
  @word_length 5
  @max_guesses 6

  @enforce_keys [:state, :answer, :guesses]
  defstruct [
    state: :playing,
    word_length: @word_length,
    max_guesses: @max_guesses,
    answer: "",
    guesses: []
  ]

  @doc """
  Create a new puzzle
  """
  def new() do
    Puzzle.new(PuzzleDictionary.random_word())
  end
  def new(answer) do
    %Puzzle{  state: :playing,
              word_length: @word_length,
              max_guesses: @max_guesses,
              answer: answer,
              guesses: []}
  end

  @doc """
  Allow changes to the rules, providing sane defaults
  """
  def set_rules(puzzle, opts) when is_list(opts) do
    word_length = Keyword.get(opts, :word_length, @word_length)
    max_guesses = Keyword.get(opts, :max_guesses, @max_guesses)

    puzzle
    |> Map.put(:word_length, word_length)
    |> Map.put(:max_guesses, max_guesses)
  end

  @doc"""
  Verify that a guess meets the rules.
  Possible return values:
      # Isn't a string
      {:error, puzzle, :invalid_arguments}

      # length is wrong
      {:error, puzzle, :invalid_length}

      # game state isn't :playing
      {:error, puzzle, :game_over}

      # word not in our game dictionary
      {:error, puzzle, :invalid_word}

      # all is well
      {:ok, puzzle}
  """
  def verify_guess(%Puzzle{state: :playing} = puzzle, guess) do
    # check is string
    # check length
    # check game status
    # verify word in dict
    with  true <- is_binary(guess),
          {:ok, @word_length} <- verify_guess_length(guess),
          {:dict, true} <- {:dict, PuzzleDictionary.verify_word(guess)}
    do
      {:ok, puzzle}
    else
      false ->                        # didn't pass in a string
        {:error, :invalid_arguments}
      {:error, :invalid_length} ->    # wrong length
        {:error, :invalid_length}
      {:dict, false} ->               # guess not in the dictionary
        {:error, :invalid_word}
      {:error, _} ->                  # we should never, ever get here
        {:error, :baby_dont_hurt_me}
    end
  end
  def verify_guess(_puzzle, _guess), do: {:error, :game_over}

  defp verify_guess_length(guess) do
    if (Enum.count(String.graphemes(guess)) == @word_length),
      do:   {:ok, @word_length},
      else: {:error, :invalid_length}
  end

  @doc """
  Make a guess with the given word
  Returns a tuple
    {:ok, puzzle} with guess and results appended to puzzle
    {:error, reason}
  """
  def make_guess(%Puzzle{state: :playing} = puzzle, guess) do
    case Guess.guess_word(guess, puzzle.answer) do
      {:ok, :correct, guess_result} ->
        # correct guess will transition the puzzle to :game_won
        {:ok, puzzle
              |> change_state(:game_won)
              |> add_result(guess_result)}
      {:ok, :incorrect, guess_result} ->
        # incorrect guess will update the puzzle and check for :game_over
        case last_guess?(puzzle) do
          true ->
            {:ok, puzzle
                  |> change_state(:game_over)
                  |> add_result(guess_result)}
          false ->
            {:ok, puzzle
                  |> add_result(guess_result)}
        end
      # don't pass in garbage!
      #TODO: I don't think I need to check for this, it should just be returned
      {:error, :invalid_length} -> {:error, :invalid_length}
      {:error, _} -> {:error, :baby_dont_hurt_me}
    end
  end
  def make_guess(_puzzle, _guess), do: {:error, :game_over}

  def change_state(puzzle, state), do: %{puzzle | state: state}
  def change_message(puzzle, message), do: %{puzzle | message: message}
  def add_result(puzzle, result) do
    %{puzzle | guesses: puzzle.guesses ++ [result]}
  end

  @doc """
  Returns true if they have taken at least one guess
  """
  def has_guessed?(puzzle) do
    Enum.count(puzzle.guesses) > 0
  end

  @doc"""
  Returns true if we haven't exceeded the maximum guesses
  """
  def guesses_remaining?(puzzle) do
    Enum.count(puzzle.guesses) < puzzle.max_guesses
  end

  @doc"""
  Returns the number of guesses remaining.
  """
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
    {:ok, result} = Guess.empty_guess(puzzle.word_length)
    List.duplicate(result, Puzzle.guesses_remaining(puzzle))
  end


  @doc """
  This will return a string describing the current state of the game.
  (Pretty much used for debugging)
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

end
