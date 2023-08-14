defmodule Subtle.Game do

  alias Subtle.{Game, Puzzle, Guess, Possibles, PuzzleDictionary}

  @verify_guesses true

  @enforce_keys [:puzzle]
  defstruct [
    verify_guesses: @verify_guesses,
    puzzle: %{},
    message: ""
  ]

  @doc """
  Create a new game with a new puzzle.
  """
  def new(opts \\ []) do
    answer = Keyword.get_lazy(opts, :answer, &PuzzleDictionary.random_word/0)

    %Game{
      verify_guesses: Keyword.get(opts, :verify, @verify_guesses),
      puzzle: Puzzle.new(answer: answer),
      message: "Guess a word."
    }
  end

  @doc """
  Allows the verify flag to be toggled, as when the user wants to enter
  disallowed words.
  """
  def set_verify(game, verify) do
    Map.put(game, :verify_guesses, verify)
  end

  @doc false
  def message(game), do: game.message

  # These are a bunch of helper functions to abstract the puzzle.
  # I'm not sure if they're really needed.
  def is_playing?(game), do: game.puzzle.state == :playing
  def state(game), do: game.puzzle.state
  def answer(game), do: game.puzzle.answer
  def guesses_remaining?(game), do: Puzzle.guesses_remaining?(game.puzzle)
  def guesses_remaining(game), do: Puzzle.guesses_remaining(game.puzzle)
  def has_guessed?(game), do: Puzzle.has_guessed?(game.puzzle)
  def summary(game), do: Puzzle.summary(game.puzzle)

  # we don't use this for the live view, but it might be useful for another view
  def guesses(game), do: Puzzle.normalized_guesses(game.puzzle)

  @doc """
  Transforms game state for the live view to display.
    [
      [%{letter: "a", hint: :correct}, ...],  # guess
      ...                                     # other guesses
      [%{letter: "x", hint: :input}, ...],    # current input
      [%{letter: " ", hint: :none}, ...],     # empty rows
      ...
    ]
  """
  def live_guess_results(game, guess) do
    guess_rows(game)            # rows with existing guesses
    |> input_row(game, guess)   # row with the input (or nothing)
    |> empty_rows(game)         # 0 or more empty rows to finish the grid
  end

  @doc """
  Get any existing guesses and convert them to display rows
  """
  def guess_rows(game) do
    # pull out just the results, place them in %{letter:, hint:} map
    game.puzzle.guesses
    |> Enum.map(fn %Guess{guess: _guess, results: results} ->
          Enum.map(results, fn {letter, hint} -> %{letter: letter, hint: hint} end)
        end )
  end

  @doc """
  Convert the user's input into a special row
  """
  def input_row(guess_rows, game, guess) do
    if guesses_remaining?(game) do
      this_row =
        String.graphemes(guess)
        |> Enum.map(fn letter -> %{letter: letter, hint: :input} end)
        |> pad_row(game.puzzle.word_length)

      Enum.concat(guess_rows, [this_row])   # must wrap in a list
    else
      guess_rows
    end
  end

  @doc """
  Return enough empty rows to pad the bottom of the game grid.
  """
  def empty_rows(game_rows, game) do
    Enum.concat(game_rows,
      List.duplicate(pad_row([], game.puzzle.word_length),   # any empty rows
        max(guesses_remaining(game) - 1, 0))
    )
  end

  @doc """
  Return a full or partial row of empty cells.
  """
  def pad_row(cells, count) do
    fill_count = count - Enum.count(cells)
    Enum.concat(cells,
      List.duplicate(%{letter: " ", hint: :none}, fill_count))
  end

  @doc """
  Verify that the guess would be appropriate.
  Will update the game's :message upon failure.
  Returns:
     {:ok, game} if ok to make a guess
     {:error, game} and :message contains error text
  """
  def verify_guess(game, guess) when game.verify_guesses do
    case Puzzle.verify_guess(puzzle = game.puzzle, guess) do
      {:ok, _puzzle} ->
        {:ok, game}
      {:error, :invalid_arguments} ->
        {:error, Map.put(game, :message,
                    guess_message(puzzle, :invalid_arguments)) }
      {:error, :invalid_length} ->
        {:error, Map.put(game, :message,
                    guess_message(puzzle, :invalid_length)) }
      {:error, :invalid_word} ->
        {:error, Map.put(game, :message,
                    guess_message(guess, :invalid_word)) }
      {:error, :game_over} ->
        {:error, Map.put(game, :message,
                    guess_message(puzzle, :game_already_finished)) }
      end
  end

  def verify_guess(game, _guess) do   # we're not verifying, continue
    {:ok, game}
  end

  @doc """
  Make a guess with the given word.
  Returns
    {:ok, game} if successful, :message is updated
    {:error, game} :message contains error text
  """
  def make_guess(game, guess) do
    guess = String.downcase(guess)

    with  {:ok, _game} <- verify_guess(game, guess),
          {:ok, puzzle} <- Puzzle.make_guess(game.puzzle, guess)
    do
      {:ok, game
            |> Map.put(:puzzle, puzzle)
            |> Map.put(:message, guess_message(puzzle, puzzle.state))
      }
    else
      {:error, :invalid_length} ->
        {:error, game
                  |> Map.put(:puzzle, game.puzzle)
                  |> Map.put(:message,
                      guess_message(game.puzzle, :invalid_length))
        }
      {:error, :game_over} ->
        {:error, game
                  |> Map.put(:puzzle, game.puzzle)
                  |> Map.put(:message,
                        guess_message(game.puzzle, :game_over))}
      {:error, :baby_dont_hurt_me} ->
        {:error, game
                  |> Map.put(:puzzle, game.puzzle)
                  |> Map.put(:message,
                        guess_message(game.puzzle, :baby_dont_hurt_me))}
      {:error, game} -> # from verify_guess, message is already set
        {:error, game}
    end
  end

  @doc """
  Return a string describing what just happened with the game.
  """
  def guess_message(guess, :invalid_word) do
    "Your guess, \"#{guess}\", must be in the dictionary."
  end

  def guess_message(puzzle, kind) do
    case kind do
      :game_won -> "You won!"
      :game_over -> "Game over! The answer was \"#{puzzle.answer}\""
      :playing -> "Guess another word."
      :invalid_arguments ->
        "Guess must be a #{puzzle.word_length} letter word."
      :invalid_length ->
        "Guess must be a #{puzzle.word_length} letter word."
      :game_already_finished ->
        "Game is already finished"
      :baby_dont_hurt_me ->
        "Baby don't hurt me! Logic path went sideways."
      :gave_up ->
        "Whomp whomp. The answer was \"#{puzzle.answer}\"."
    end
  end

  @doc """
  This peril is just too perilous. Game over man, I'm losing!
  Just let me quit the game already.
  """
  def game_over_man(game) do
    game
    |> Map.put(:puzzle, Puzzle.change_state(game.puzzle, :game_over))
    |> Map.put(:message, guess_message(game.puzzle, :gave_up))
  end

  @doc """
  Returns a map a letters already guessed, marking them for display.

  The LiveView uses this to display a color-coded "keyboard" view to convery
  "these letters aren't in the answer" or "these letters are in the answer".

  Example:
    Given "paper" and a guess of "apple" we get
      %{
        "a" => [:wrong_position],
        "e" => [:wrong_position],
        "l" => [:wrong_letter],
        "p" => [:correct, :wrong_position]
      }
  """
  def letters_used(game) do
    # 1) Go through all the letters already guessed
    # 2) Create a map with results for each letter guessed
    # [{"b", :correct}, {"c", :wrong_letter}, {"b", :wrong_position}] ->
    # %{"b" => [:correct, :wrong_position]}, "c" => [:wrong_letter]}
    game.puzzle.guesses
    |> Enum.reduce([], fn x, acc -> [x.results | acc] end)
    |> List.flatten()
    |> reduce_letters()
  end

  @doc false
  def reduce_letters(l) do
    # This is similar to frequencies() but accumulating results, not count
    Enum.reduce(l, %{}, fn {letter, result}, map ->
      case map do
        %{^letter => value} -> %{map | letter => [result | value]}
        %{} -> Map.put(map, letter, [result])
      end
    end)
  end

  @doc """
  Returns a string of words that might be the answer for the game

  ## Examples
    Game.new("paper")
    Game.make_guess("stare")
    Game.make_guess("panic")
    Game.process_guesses
    "paddy, paler, papal, paper, parer, parka, parry, payee, payer, ..."
  """
  # guidance is :simple | :intermediate
  @answer_defaults %{max_words: 10, guidance: :simple}

  def available_answers(game, options \\ [])

  def available_answers(game, _options) when game.puzzle.guesses == [] do
    "You haven't made a guess yet!"
  end

  def available_answers(game, options) do
    %{max_words: max_words, guidance: guidance} = Enum.into(options, @answer_defaults)

    Possibles.possible_words(game, guidance)
    |> inspect([limit: max_words, as_strings: true])
    |> String.replace("\"", "")
    |> String.slice(1..-2//1)     # remove the trailing ", "
  end

end
